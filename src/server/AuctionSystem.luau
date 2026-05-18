--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local AuctionEvent = Events:WaitForChild("AuctionEvent")
local NPCSystem = require(ServerScriptService.Server.NPCSystem)
local EconomySystem = require(ServerScriptService.Server.EconomySystem)
local InventorySystem = require(ServerScriptService.Server.InventorySystem)
local NotificationSystem = require(ServerScriptService.Server.NotificationSystem)
local TTSSystem = require(ServerScriptService.Server.TTSSystem)

local tts = TTSSystem.new()

-- TTS rate-limit: minimum seconds between spoken bids
local TTS_COOLDOWN = 2
local lastTTSTime = 0

local CatchPhrase = {
	" here",
	" over there",
	"... do I hear more?",
	"... last chance",
	"... going to the highest bidder",
	"",
	"!",
	"...",
	".",
	"",
}

export type Auction = {
	started: boolean,
	item: any,
	price: number,
	averagePrice: number,
	currentBid: number,
	currentBidderName: string,
	endDelay: number,
	lastBidTime: number,
}

export type AuctionClass = {
	Auction: Auction,
	_taskId: number,
	_finished: BindableEvent,
	Finished: RBXScriptSignal,
	StartAuction: (self: AuctionClass, item: any, endDelay: number) -> (),
	EndAuction: (self: AuctionClass) -> (),
	Bid: (self: AuctionClass, bidder: any, amount: number) -> (),
	ScheduleAuctionEnd: (self: AuctionClass) -> (),
	GetTimeRemaining: (self: AuctionClass) -> number,
	UpdateAllClients: (self: AuctionClass) -> (),
	Destroy: (self: AuctionClass) -> (),
}

local AuctionSystem = {}
AuctionSystem.__index = AuctionSystem

function AuctionSystem.Start(): ()
	print("Auction System Started")
end

function AuctionSystem.new(): AuctionClass
	local finished = Instance.new("BindableEvent")
	local self = setmetatable({
		_taskId = 0 :: number,
		_finished = finished,
		Finished = finished.Event,
		Auction = {
			started = false,
			item = {} :: any,
			price = 0,
			averagePrice = 0,
			currentBid = 0,
			currentBidderName = "Nobody",
			endDelay = 0,
			lastBidTime = 0,
		},
	}, AuctionSystem)
	return (self :: any) :: AuctionClass
end

-- Use dot notation throughout so `self` is only declared once per function,
-- eliminating all LocalShadow warnings.

function AuctionSystem.StartAuction(self: AuctionClass, item: any, endDelay: number): ()
	print("NEW AUCTION CREATED: ", item.Name, "starting at", item.Price)

	self.Auction.started = true
	self.Auction.item = item
	self.Auction.price = item.Price
	self.Auction.averagePrice = item.BasePrice
	self.Auction.currentBid = 0
	self.Auction.currentBidderName = "Nobody"
	self.Auction.endDelay = endDelay
	self.Auction.lastBidTime = os.clock()
	self:UpdateAllClients()
	self:ScheduleAuctionEnd()
end

function AuctionSystem.EndAuction(self: AuctionClass): ()
	local bidderName = self.Auction.currentBidderName
	local item = self.Auction.item
	local finalPrice = self.Auction.currentBid

	self.Auction.started = false
	self:UpdateAllClients()
	self._finished:Fire()

	if bidderName == "Nobody" then return end

	local Players = game:GetService("Players")
	local winner = Players:FindFirstChild(bidderName)

	if winner then
		EconomySystem.RemoveMoney(winner, finalPrice)
		InventorySystem.AddItem(winner, item.Name, item.Amount, item.Condition, item.Price, item.Description)
	end
end

function AuctionSystem.Bid(self: AuctionClass, bidder: any, amount: number): ()
	if not self.Auction.started or self:GetTimeRemaining() <= 0 then return end

	local isNPC = typeof(bidder) == "table"
	local currentBalance = if isNPC then bidder.balance else EconomySystem.GetBalance(bidder)
	local bidderName = if isNPC then bidder.name else bidder.Name

	-- Prevent an NPC from outbidding itself
	if bidderName == self.Auction.currentBidderName then return end

	if amount <= self.Auction.currentBid then
		if not isNPC then
			NotificationSystem.Notify(bidder, { message = "Cannot bid under current bid!", type = "error", duration = 3 })
		end
		return
	end

	if self.Auction.currentBid > 0 and amount < self.Auction.currentBid * 1.1 then
		if not isNPC then
			NotificationSystem.Notify(bidder, { message = "Bid must be at least 10% higher than the current bid!", type = "error", duration = 3 })
		end
		return
	end

	if currentBalance < amount then
		if not isNPC then
			NotificationSystem.Notify(bidder, { message = "You can't afford to bid this much!", type = "error", duration = 3 })
		end
		return
	end

	-- Rate-limited TTS: skip if spoken too recently
	local now = os.clock()
	if now - lastTTSTime >= TTS_COOLDOWN then
		lastTTSTime = now
		local randomPhrase = CatchPhrase[math.random(1, #CatchPhrase)]
		tts:Speak(tostring(amount) .. randomPhrase, "1", 1.35, 0.6, 1)
	end

	self.Auction.currentBid = amount
	self.Auction.currentBidderName = bidderName
	self.Auction.lastBidTime = os.clock()

	self:ScheduleAuctionEnd()
	self:UpdateAllClients()
end

function AuctionSystem.ScheduleAuctionEnd(self: AuctionClass): ()
	self._taskId += 1
	local capturedId = self._taskId
	local endDelay = self.Auction.endDelay

	-- "Going once" at 2/3 of the delay remaining
	task.delay(endDelay * 0.33, function()
		if self._taskId ~= capturedId then return end
		tts:Speak("Going once!", "1", 1.35, 0.6, 1)
	end)

	-- "Going twice" at 1/3 of the delay remaining
	task.delay(endDelay * 0.66, function()
		if self._taskId ~= capturedId then return end
		tts:Speak("Going twice!", "1", 1.35, 0.6, 1)
	end)

	-- "Sold!" + winner name just before EndAuction fires
	task.delay(endDelay - 0.5, function()
		if self._taskId ~= capturedId then return end
		local winner = self.Auction.currentBidderName
		tts:Speak("Sold to " .. winner .. "!", "1", 1.35, 0.6, 1)
	end)

	task.delay(endDelay, function()
		if self._taskId ~= capturedId then return end
		self:EndAuction()
	end)
end

function AuctionSystem.GetTimeRemaining(self: AuctionClass): number
	if not self.Auction.started then return 0 end
	return math.max(0, self.Auction.endDelay - (os.clock() - self.Auction.lastBidTime))
end

function AuctionSystem.UpdateAllClients(self: AuctionClass): ()
	local endAt = if self.Auction.started
		then self.Auction.lastBidTime + self.Auction.endDelay
		else 0
	AuctionEvent:FireAllClients("update", self.Auction, NPCSystem.ActiveNPCs, endAt)
end

function AuctionSystem.Destroy(self: AuctionClass): ()
	self._finished:Destroy()
end

return AuctionSystem