--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataSystem = require(ServerScriptService.Server.DataSystem)

local EconomySystem = {}

function EconomySystem.Start(): ()
	print("Economy System Started")
end

function EconomySystem.SetupLeaderstats(player: Player): ()
	local profile = DataSystem.GetProfile(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = profile.Money
	money.Parent = leaderstats
end

function EconomySystem.GiveMoney(player: Player, amount: number): ()
	local profile = DataSystem.GetProfile(player)
	profile.Money += amount
	EconomySystem.UpdateLeaderstats(player)
end

function EconomySystem.RemoveMoney(player: Player, amount: number): boolean
	local profile = DataSystem.GetProfile(player)
	if profile.Money - amount < 0 then
		warn("Not enough money")
		return false
	end
	profile.Money -= amount
	EconomySystem.UpdateLeaderstats(player)
	return true
end

function EconomySystem.GetBalance(player: Player): number
	local profile = DataSystem.GetProfile(player)
	return profile.Money
end

function EconomySystem.UpdateLeaderstats(player: Player): ()
	local profile = DataSystem.GetProfile(player)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local money = leaderstats:FindFirstChild("Money") :: IntValue
	if not money then return end
	money.Value = profile.Money
end

Players.PlayerAdded:Connect(function(player: Player)
	EconomySystem.SetupLeaderstats(player)
	EconomySystem.GiveMoney(player, 1000)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	DataSystem.RemoveProfile(player)
end)

return EconomySystem