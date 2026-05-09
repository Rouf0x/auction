local InventoryHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage:WaitForChild("Events")
local Player = game.Players.LocalPlayer
local InventoryEvent = Events:WaitForChild("InventoryEvent")
local InventoryGui = Player.PlayerGui:WaitForChild("InventoryGui")
local InventoryFrame = InventoryGui:WaitForChild("Background")
local ItemTemplate = InventoryGui:WaitForChild("ItemTemplate")
local Tooltip = InventoryGui:WaitForChild("Tooltip")
local Keybinds = InventoryGui:WaitForChild("Keybinds")

function InventoryHandler.Start()
	print('Inventory Handler Started')
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		ProcessInput(input, gameProcessed)
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		ProcessInput(input, gameProcessed)
	end)
	
	RunService.RenderStepped:Connect(UpdateTooltipPosition)
end

function InventoryHandler:UpdateInventory()
	InventoryEvent:FireServer("getItems")
end

function OpenCloseInventory()
	InventoryFrame.Visible = not InventoryFrame.Visible
	Keybinds.Visible = InventoryFrame.Visible
	
	if InventoryFrame.Visible then return end
	Tooltip.Visible = false
end

function ProcessInput(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.LeftControl then
		OpenCloseInventory()
	end
end

function UpdateInventory(items)
	for i,v in pairs(InventoryFrame:GetChildren()) do
		if v:IsA("CanvasGroup") then v:Destroy() end
	end
	
	for _, item in pairs(items) do
		local itemInterface = ItemTemplate:Clone()
		itemInterface.Name = item.Name
		itemInterface.Visible = true
		itemInterface.Parent = InventoryFrame
		itemInterface.Amount.Text = item.Amount
		itemInterface.LayoutOrder = item.Amount
		itemInterface:SetAttribute("Amount", item.Amount)
		itemInterface:SetAttribute("Name", item.Name)
		itemInterface:SetAttribute("Condition", item.Condition)
		itemInterface:SetAttribute("Description", item.Description)
		itemInterface:SetAttribute("Price", item.Price)
		
		itemInterface.MouseEnter:Connect(function()
			local name = itemInterface:GetAttribute("Name")
			local description = itemInterface:GetAttribute("Description")
			local condition = itemInterface:GetAttribute("Condition")
			local price = itemInterface:GetAttribute("Price")
			local text = "<b>" .. name .. "</b>\n" .. description .. "\n<i>" .. condition .. '</i> \n <font color="rgb(0,125,0)">$' .. price .. "</font>/unit"
			Tooltip.Text = text
			Tooltip.Visible = true
		end)
		
		itemInterface.MouseLeave:Connect(function()
			Tooltip.Visible = false
		end)
		
		itemInterface.ClickDetector.MouseButton1Click:Connect(function()
			InventoryEvent:FireServer("sell", item.Name, item.Condition, 1)
		end)
	end
end

function UpdateTooltipPosition()
	if not Tooltip.Visible then return end
	
	local mousePos = UserInputService:GetMouseLocation()
	Tooltip.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y - 35)
end

InventoryEvent.OnClientEvent:Connect(function(action, ...)
	if action == "items" then
		local items = ...
	end
	
	if action == "update" then
		local items = ...
		UpdateInventory(items)
	end
end)

return InventoryHandler
