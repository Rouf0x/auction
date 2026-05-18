local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuctionSystem = require(ServerScriptService.Server.AuctionSystem)
local NPCSystem = require(ServerScriptService.Server.NPCSystem)
local AuctionEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("AuctionEvent")

local ITEMS_POOL = {
	{ Name = "Antique Vase",   BasePrice = 500,  Description = "A fragile relic from the past." },
	{ Name = "Rusty Sword",    BasePrice = 150,  Description = "It's seen better days, but it's sharp." },
	{ Name = "Golden Idol",    BasePrice = 2000, Description = "Shiny, heavy, and potentially cursed." },
	{ Name = "Old Boot",       BasePrice = 10,   Description = "Someone actually lost this?" },
	{ Name = "Mysterious Orb", BasePrice = 1200, Description = "It pulses with a faint purple light." },
}

local CONDITIONS = {
	{ Status = "Poor",   Multiplier = 0.5 },
	{ Status = "Normal", Multiplier = 1.0 },
	{ Status = "Great",  Multiplier = 1.5 },
	{ Status = "Mint",   Multiplier = 2.0 },
}

local function GenerateRandomItem()
	local base = ITEMS_POOL[math.random(1, #ITEMS_POOL)]
	local cond = CONDITIONS[math.random(1, #CONDITIONS)]
	return {
		Name        = string.format("%s (Avg. Price: %d)", base.Name, base.BasePrice),
		BasePrice   = base.BasePrice,
		Price       = math.floor(base.BasePrice * cond.Multiplier),
		Condition   = cond.Status,
		Amount      = 1,
		Description = base.Description,
	}
end

local auctionRunning = false

while true do
	if auctionRunning then
		-- Should never happen, but guard against it
		warn("AuctionLoop: previous auction still running, waiting...")
		task.wait(1)
		continue
	end

	auctionRunning = true
	NPCSystem.ResetNPCs()

	local auction = AuctionSystem.new()

	local con = AuctionEvent.OnServerEvent:Connect(function(player, action, ...)
		if action == "bid" then
			auction:Bid(player, ...)
		elseif action == "update" then
			auction:UpdateAllClients()
		end
	end)

	-- Start the auction first so NPCs see started = true immediately
	auction:StartAuction(GenerateRandomItem(), 20)

	-- NPC loop runs only while this auction is live
	local npcLoopRunning = true
	task.spawn(function()
		while npcLoopRunning do
			NPCSystem.UpdateNPCs(auction)
			task.wait(0.5)
		end
	end)

	auction.Finished:Wait()

	npcLoopRunning = false
	con:Disconnect()
	auction:Destroy()
	auctionRunning = false

	task.wait(3)
end