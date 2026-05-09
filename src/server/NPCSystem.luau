--!strict

local NPC = {}
NPC.__index = NPC

type NPCInstance = {
	name: string,
	aggressivity: number,
	balance: number,
	
	isThinking: boolean,
	targetBid: number?,
	nextBidTime: number?,
	
	GetInfo: (self: NPCInstance) -> any,
	ProcessAction: (self: NPCInstance, number, number) -> number,
	Hesitate: (self: NPCInstance, number) -> number,
	Update: (self: NPCInstance, avgPrice: number, currentBid: number, currentBidder: string) -> number?,
	RotatePersonality: (self: NPCInstance) -> (),
}

-- Configuration & Data
local adjectives = {
	"Swift", "Glowy", "Eccentric", "Cosmic", "Boring", "Zesty",
	"Infamous", "Clumsy", "Elegant", "Uninterested", "Heavenly", "Kind",
	"Feeble", "Cluttered", "Flagrant", "Enormous", "Suspicious", "Pale",
	"Tough", "Bloody", "Obsolete", "Cheap", "Stinky", "Rusty",
	"Flimsy", "Rotten", "Stale", "Rabid", "Lush", "Functional",
	"Icky", "Ethereal", "Dull", "Cloudy", "Crazy", "Dusty", "Rebel",
}

local nouns = {
	"Puma", "Skull", "Snake", "Congressman", "Cat", "Dog",
	"Lamb", "Troop", "Walnut", "Balaclava", "Space", "Scam",
	"Wave", "Water", "Leprosy", "Oat", "Screwdriver", "Citizen",
	"Bush", "Site", "Tamale", "Tide", "Flare", "Building",
	"Marshmallow", "Cheese", "Rat", "Rabbit", "Cheeseburger", "Jellyfish",
	"Kitten", "Mouse", "Raccoon", "Shark", "Whale", "Shrimp", "Sandcastle"
}

local function weightedAverage(min: number, max: number): number
	local ran = math.sqrt(math.random())
	local invFactor = 1 - ran
	return math.floor(min + (invFactor * (max - min)))
end

local function generateName(): string
	local adj = adjectives[math.random(#adjectives)]
	local noun = nouns[math.random(#nouns)]
	local randomNumber = math.random(1000, 9999)
	return adj .. noun .. randomNumber 
end



function NPC.new(): NPCInstance
	local self = setmetatable({}, NPC)

	self.name = generateName()
	self.aggressivity = math.random(1, 100)
	self.balance = weightedAverage(500, 3000)
	self.isThinking = false
	self.nextBidTime = nil
	self.targetBid = nil

	return (self :: any) :: NPCInstance
end

function NPC:GetInfo(): string
	return self
end

function NPC:Hesitate(currentBid: number): number
	local self = self :: NPCInstance
	
	local aggroWait = (1 -  (self.aggressivity / 100)) * 4
	local priceRatio = currentBid / self.balance
	local stressWait

	if priceRatio > 0.8 then
		stressWait = 2.5
	else
		stressWait = 1
	end

	local hesitation = aggroWait + stressWait + math.random()
	
	return hesitation
end

function NPC:ProcessAction(avgPrice: number, currentBid: number): number
	local self = self :: NPCInstance

	local multiplier = 0.7 + (self.aggressivity / 100) * 0.5
	local maxBudget = avgPrice * multiplier

	if currentBid >= maxBudget or currentBid >= self.balance then
		return 0
	end

	-- If bid is 0, start at ~5-10% of avg price. Otherwise, bid 10-20% higher than current.
	local minIncrement, maxIncrement
	if currentBid == 0 then
		minIncrement = math.floor(avgPrice * 0.05)
		maxIncrement = math.floor(avgPrice * 0.15)
	else
		minIncrement = math.floor(currentBid * 1.1)
		maxIncrement = math.floor(currentBid * 1.25)
	end

	-- Ensure min isn't higher than max for math.random
	if minIncrement >= maxIncrement then maxIncrement = minIncrement + 1 end

	local finalBid = math.random(minIncrement, maxIncrement)

	-- Don't bid more than budget or balance
	if finalBid > maxBudget then finalBid = maxBudget end
	if finalBid > self.balance then finalBid = self.balance end

	-- Ensure the final calculated bid is actually an improvement
	if finalBid <= currentBid then return 0 end

	return math.floor(finalBid)
end

local NPCSystem = {
	ActiveNPCs = {} :: {NPCInstance}
}

function NPC:RotatePersonality()
	local self = self :: NPCInstance

	-- removed the redundant first balance assignment
	self.aggressivity = math.random(1, 100)
	self.balance = weightedAverage(500, 3000)
	self.isThinking = false
	self.targetBid = nil
	self.nextBidTime = nil
end

function NPCSystem.ResetNPCs()
	for _, npc in ipairs(NPCSystem.ActiveNPCs) do
		npc:RotatePersonality()
	end
end

function NPC:Update(avgPrice: number, currentBid: number, currentBidder: string): number?
	local self = self :: NPCInstance
	local currentTime = os.clock()

	-- If I am currently winning, reset my thinking state
	if currentBidder == self.name then
		self.isThinking = false
		self.targetBid = nil
		self.nextBidTime = nil
		return nil
	end

	if not self.isThinking then
		local bidAmount = self:ProcessAction(avgPrice, currentBid)
		if bidAmount <= currentBid then return nil end

		self.isThinking = true
		self.targetBid = bidAmount
		self.nextBidTime = currentTime + self:Hesitate(currentBid)
		return nil
	end

	-- NEW: If someone else bids higher than or equal to my planned targetBid while I'm thinking, reset.
	if self.isThinking and self.targetBid and currentBid >= self.targetBid then
		self.isThinking = false
		self.targetBid = nil
		self.nextBidTime = nil
		return nil
	end

	if self.isThinking and self.nextBidTime and currentTime >= self.nextBidTime then
		local finalBid = self.targetBid or 0

		self.isThinking = false
		self.nextBidTime = nil
		self.targetBid = nil

		-- Final check to ensure we aren't outbid at the last millisecond
		if finalBid <= currentBid then return nil end
		return finalBid
	end

	return nil
end

function NPCSystem.UpdateNPCs(auction: any)
	local shuffledNPCs = {}
	for _, npc in ipairs(NPCSystem.ActiveNPCs) do
		table.insert(shuffledNPCs, npc)
	end

	for i = #shuffledNPCs, 2, -1 do
		local j = math.random(1, i)
		shuffledNPCs[i], shuffledNPCs[j] = shuffledNPCs[j], shuffledNPCs[i]
	end

	for _, npc in ipairs(shuffledNPCs) do
		local npcRef = npc :: NPCInstance

		local currentBidder = auction.Auction.currentBidder
		local bidderName = currentBidder and currentBidder.name or ""

		local bid = npc:Update(auction.Auction.averagePrice, auction.Auction.currentBid, bidderName)

		if bid then
			auction:Bid(npcRef, bid)
			break
		end
	end
end

function NPC:RemoveMoney(amount: number): ()
	local self = self :: NPCInstance
	self.balance -= amount
end

function NPC:AddItem(name: string, amount: number, condition: string, price: number, desc: string)
	local self = self :: NPCInstance
	self.balance += price
	
	self.isThinking = false
	self.targetBid = nil
	self.nextBidTime = nil
	
	print(self.balance)
end

function NPCSystem.Start()
	print("NPC System Started") 

	for i = 1, 5 do
		local newNPC = NPC.new()
		table.insert(NPCSystem.ActiveNPCs, newNPC)
	end
end

return NPCSystem