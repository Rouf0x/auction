--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Paths
local Events = ReplicatedStorage:WaitForChild("Events")
local AuctionEvent = Events:WaitForChild("AuctionEvent")
local NPCSystem = require(ServerScriptService.Server.NPCSystem)

-- Modules
local EconomySystem = require(ServerScriptService.Server.EconomySystem)
local InventorySystem = require(ServerScriptService.Server.InventorySystem)
local NotificationSystem = require(ServerScriptService.Server.NotificationSystem)

-- Types
export type Auction = {
	started: boolean,
	item: any,
	price: number,
	averagePrice: number,
	currentBid: number,
	currentBidder: any?,
	duration: number,
	startTime: number,
}

export type AuctionClass = {
	Auction: Auction,
	StartAuction: (self: AuctionClass, item: any, timer: number) -> (),
	EndAuction: (self: AuctionClass) -> (),
	Bid: (self: AuctionClass, bidder: any, amount: number) -> (),
	ScheduleAuctionEnd: (self: AuctionClass) -> (),
	GetTimeRemaining: (self: AuctionClass) -> number,
	UpdateAllClients: (self: AuctionClass) -> (),
	ResetAuctionState: (self: AuctionClass) -> (),
}

local AuctionSystem = {}
AuctionSystem.__index = AuctionSystem

function AuctionSystem.Start(): ()
	print("Auction System Started")
end

function AuctionSystem.new(): AuctionClass
	local data = setmetatable({
		Auction = {
			started = false,
			item = "",
			price = 0,
			averagePrice = 0,
			currentBid = 0,
			currentBidder = nil :: any?,
			duration = 0,
			startTime = 0,
		},
	}, AuctionSystem)

	return (data :: any) :: AuctionClass
end

function AuctionSystem:StartAuction(item: any, duration: number): ()
	local self: AuctionClass = self

	self.Auction.started = true
	self.Auction.currentBid = 0
	self.Auction.currentBidder = nil
	self.Auction.item = item
	self.Auction.price = item.Price
	self.Auction.averagePrice = item.BasePrice
	self.Auction.duration = duration
	self.Auction.startTime = os.clock()

	self:UpdateAllClients()
	self:ScheduleAuctionEnd()
end

function AuctionSystem:ResetAuctionState(): ()
	local self: AuctionClass = self

	self.Auction.started = false
	self.Auction.currentBid = 0
	self.Auction.currentBidder = nil
	self.Auction.item = { Name = "", Amount = 0, Condition = "", Price = 0, Description = "" }
	self:UpdateAllClients()
end

function AuctionSystem:EndAuction(): ()
	local self: AuctionClass = self

	local winner: any = self.Auction.currentBidder
	local item: any = self.Auction.item
	local finalPrice: number = self.Auction.currentBid

	if not winner or item == "" then
		self:ResetAuctionState()
		return
	end

	local isPlayer = typeof(winner) == "Instance"

	if isPlayer then
		-- Route through stateless systems, DataSystem is the source of truth
		EconomySystem.RemoveMoney(winner, finalPrice)
		InventorySystem.AddItem(winner, item.Name, item.Amount, item.Condition, item.Price, item.Description)
	else
		-- NPC: update their balance directly
		winner.balance -= finalPrice
	end

	self:ResetAuctionState()
end

function AuctionSystem:Bid(bidder: any, amount: number): ()
	local self: AuctionClass = self

	if not self.Auction.started or self:GetTimeRemaining() <= 0 then return end

	local isNPC = typeof(bidder) == "table"
	local currentBalance = 0

	if isNPC then
		currentBalance = bidder.balance
	else
		currentBalance = EconomySystem.GetBalance(bidder)
	end

	if amount <= self.Auction.currentBid then
		if not isNPC then
			NotificationSystem.Notify(bidder, {
				message = "Cannot bid under current bid!",
				type = "error",
				duration = 3,
			})
		end
		return
	end

	if amount < (self.Auction.currentBid * 1.1) then
		if not isNPC then
			NotificationSystem.Notify(bidder, {
				message = "Bid must be at least 10% higher than the current bid!",
				type = "error",
				duration = 3,
			})
		end
		return
	end

	if currentBalance < amount then
		if not isNPC then
			NotificationSystem.Notify(bidder, {
				message = "You can't afford to bid this much!",
				type = "error",
				duration = 3,
			})
		end
		return
	end

	self.Auction.currentBid = amount
	self.Auction.currentBidder = bidder
	self:UpdateAllClients()
end

function AuctionSystem:ScheduleAuctionEnd(): ()
	local self: AuctionClass = self

	task.delay(self.Auction.duration, function()
		self:EndAuction()
	end)
end

function AuctionSystem:UpdateAllClients(): ()
	AuctionEvent:FireAllClients("update", self.Auction, NPCSystem.ActiveNPCs)
end

function AuctionSystem:GetTimeRemaining(): number
	local self: AuctionClass = self

	if not self.Auction.started then return 0 end

	local endTime = self.Auction.startTime + self.Auction.duration
	return math.max(0, endTime - os.clock())
end

return AuctionSystem