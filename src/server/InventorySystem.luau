--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Events = ReplicatedStorage:WaitForChild("Events")
local InventoryEvent = Events:WaitForChild("InventoryEvent")

local EconomySystem = require(ServerScriptService.Server.EconomySystem)
local NotificationSystem = require(ServerScriptService.Server.NotificationSystem)
local DataSystem = require(ServerScriptService.Server.DataSystem)

local InventorySystem = {}

function InventorySystem.Start(): ()
	print("Inventory System Started")
end

function InventorySystem.GetItems(player: Player): { DataSystem.ItemData }
	local profile = DataSystem.GetProfile(player)
	return profile.Inventory
end

function InventorySystem.GetItem(player: Player, name: string, condition: string): (DataSystem.ItemData?, number?)
	local profile = DataSystem.GetProfile(player)
	for index, item in ipairs(profile.Inventory) do
		if item.Name == name and item.Condition == condition then
			return item, index
		end
	end
	return nil, nil
end

function InventorySystem.AddItem(player: Player, itemName: string, amount: number, condition: string, basePrice: number, description: string): ()
	local profile = DataSystem.GetProfile(player)

	local item, _ = InventorySystem.GetItem(player, itemName, condition)
	if item then
		item.Amount += amount
		InventorySystem.UpdateClient(player)
		return
	end

	table.insert(profile.Inventory, {
		Name = itemName,
		Amount = amount,
		Condition = condition,
		Price = basePrice,
		Description = description,
	})

	InventorySystem.UpdateClient(player)
end

function InventorySystem.RemoveItem(player: Player, name: string, condition: string, amount: number): ()
	local profile = DataSystem.GetProfile(player)

	local item, index = InventorySystem.GetItem(player, name, condition)
	if not item or not index then return end

	item.Amount -= amount
	if item.Amount <= 0 then
		table.remove(profile.Inventory, index)
	end

	InventorySystem.UpdateClient(player)
end

function InventorySystem.Sell(player: Player, itemName: string, condition: string, amount: number): ()
	local item, _ = InventorySystem.GetItem(player, itemName, condition)
	if not item then return end

	local payout = item.Price * amount
	InventorySystem.RemoveItem(player, item.Name, item.Condition, amount)
	EconomySystem.GiveMoney(player, payout)

	NotificationSystem.Notify(player, {
		message = "You sold " .. amount .. " " .. itemName .. " for $" .. payout,
		type = "info",
		duration = 5,
	})
end

function InventorySystem.GetTotalValue(player: Player, itemName: string, condition: string): number
	local item, _ = InventorySystem.GetItem(player, itemName, condition)
	if not item then return 0 end
	return item.Price * item.Amount
end

function InventorySystem.UpdateClient(player: Player): ()
	InventoryEvent:FireClient(player, "update", InventorySystem.GetItems(player))
end

InventoryEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "getItems" then
		InventoryEvent:FireClient(player, "items", InventorySystem.GetItems(player))
		return
	end

	if action == "sell" then
		InventorySystem.Sell(player, ...)
	end
end)

return InventorySystem