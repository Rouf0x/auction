local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuctionSystem = require(ServerScriptService.Server.AuctionSystem)
local NPCSystem = require(ServerScriptService.Server.NPCSystem)
local Events = ReplicatedStorage:WaitForChild("Events")
local AuctionEvent = Events:WaitForChild("AuctionEvent")

-- Configuration for random generation
local ITEMS_POOL = {
	{Name = "Antique Vase", BasePrice = 500, Description = "A fragile relic from the past."},
	{Name = "Rusty Sword", BasePrice = 150, Description = "It's seen better days, but it's sharp."},
	{Name = "Golden Idol", BasePrice = 2000, Description = "Shiny, heavy, and potentially cursed."},
	{Name = "Old Boot", BasePrice = 10, Description = "Someone actually lost this?"},
	{Name = "Mysterious Orb", BasePrice = 1200, Description = "It pulses with a faint purple light."}
}

local CONDITIONS = {
	{Status = "Poor", Multiplier = 0.5},
	{Status = "Normal", Multiplier = 1.0},
	{Status = "Great", Multiplier = 1.5},
	{Status = "Mint", Multiplier = 2.0}
}

-- Function to generate a random item
local function GenerateRandomItem()
	local randomBase = ITEMS_POOL[math.random(1, #ITEMS_POOL)]
	local randomCond = CONDITIONS[math.random(1, #CONDITIONS)]

	local actualPrice = math.floor(randomBase.BasePrice * randomCond.Multiplier)

	return {
		Name = string.format("%s (Avg. Price: %d)", randomBase.Name, randomBase.BasePrice),
		BasePrice = randomBase.BasePrice, -- Publicly known
		Price = actualPrice,             -- Hidden until sold
		Condition = randomCond.Status,
		Amount = 1,
		Description = randomBase.Description
	}
end

-- Main Server Loop
while true do
	NPCSystem.ResetNPCs()
	local item = GenerateRandomItem()
	local auction = AuctionSystem.new()
	auction:StartAuction(item, 60)

	local npcLoopRunning = true
	
	local con = AuctionEvent.OnServerEvent:Connect(function(player, action, ...)
		if action == "bid" then
			auction:Bid(player, ...)
		elseif action == "update" then
			auction:UpdateAllClients()
		end
	end)

	task.spawn(function()
		while npcLoopRunning do
			NPCSystem.UpdateNPCs(auction)
			task.wait(0.5)
		end
	end)

	task.wait(65)
	npcLoopRunning = false 
	con:Disconnect()
end