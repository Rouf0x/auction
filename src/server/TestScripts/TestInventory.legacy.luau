local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local InventorySystem = require(ServerScriptService.Server.InventorySystem)

Players.PlayerAdded:Connect(function(player)
	local inventory = InventorySystem.new(player)
	print(inventory:GetItems())
	inventory:AddItem("Test Item", 1)
	print(inventory:GetItems())
	inventory:RemoveItem("Test Item", 1)
	print(inventory:GetItems())
end)