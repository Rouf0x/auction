-- LocalScript inside StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage:WaitForChild("Events")
local AuctionEvent = Events:WaitForChild("AuctionEvent")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Current auction state (updated via AuctionEvent)
local currentAuction = nil

-- ══════════════════════════════════════════
-- BUILD GUI
-- ══════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCDebugGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main frame (top-right corner)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 500)
mainFrame.Position = UDim2.new(1, -350, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NPC DEBUG"
titleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.Code
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 22)
toggleBtn.Position = UDim2.new(1, -68, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
toggleBtn.Text = "HIDE"
toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.Code
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = titleBar
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

-- Auction info section
local auctionFrame = Instance.new("Frame")
auctionFrame.Name = "AuctionInfo"
auctionFrame.Size = UDim2.new(1, -16, 0, 90)
auctionFrame.Position = UDim2.new(0, 8, 0, 40)
auctionFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
auctionFrame.BorderSizePixel = 0
auctionFrame.Parent = mainFrame
Instance.new("UICorner", auctionFrame).CornerRadius = UDim.new(0, 6)

local auctionText = Instance.new("TextLabel")
auctionText.Size = UDim2.new(1, -12, 1, -8)
auctionText.Position = UDim2.new(0, 6, 0, 4)
auctionText.BackgroundTransparency = 1
auctionText.Text = "Waiting for auction..."
auctionText.TextColor3 = Color3.fromRGB(160, 220, 160)
auctionText.TextSize = 11
auctionText.Font = Enum.Font.Code
auctionText.TextXAlignment = Enum.TextXAlignment.Left
auctionText.TextYAlignment = Enum.TextYAlignment.Top
auctionText.TextWrapped = true
auctionText.Parent = auctionFrame

-- NPC section label
local npcSectionLabel = Instance.new("TextLabel")
npcSectionLabel.Size = UDim2.new(1, -16, 0, 18)
npcSectionLabel.Position = UDim2.new(0, 8, 0, 138)
npcSectionLabel.BackgroundTransparency = 1
npcSectionLabel.Text = "── NPCS ──────────────────────────"
npcSectionLabel.TextColor3 = Color3.fromRGB(80, 80, 100)
npcSectionLabel.TextSize = 10
npcSectionLabel.Font = Enum.Font.Code
npcSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
npcSectionLabel.Parent = mainFrame

-- Scrolling frame for NPC cards
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -164)
scrollFrame.Position = UDim2.new(0, 8, 0, 158)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

-- ══════════════════════════════════════════
-- NPC CARD BUILDER
-- ══════════════════════════════════════════

local npcCards = {} -- name -> frame

local function getOrCreateCard(npcName)
	if npcCards[npcName] then return npcCards[npcName] end

	local card = Instance.new("Frame")
	card.Name = npcName
	card.Size = UDim2.new(1, 0, 0, 78)
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	card.BorderSizePixel = 0
	card.Parent = scrollFrame
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -70, 0, 18)
	nameLabel.Position = UDim2.new(0, 8, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcName
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.Code
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Status badge
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(0, 62, 0, 16)
	statusLabel.Position = UDim2.new(1, -68, 0, 6)
	statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	statusLabel.Text = "IDLE"
	statusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
	statusLabel.TextSize = 10
	statusLabel.Font = Enum.Font.Code
	statusLabel.BorderSizePixel = 0
	statusLabel.Parent = card
	Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 4)

	-- Balance + aggressivity text
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -16, 0, 14)
	statsLabel.Position = UDim2.new(0, 8, 0, 26)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = ""
	statsLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
	statsLabel.TextSize = 10
	statsLabel.Font = Enum.Font.Code
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = card

	-- Target bid / next bid timer
	local bidLabel = Instance.new("TextLabel")
	bidLabel.Name = "BidLabel"
	bidLabel.Size = UDim2.new(1, -16, 0, 14)
	bidLabel.Position = UDim2.new(0, 8, 0, 42)
	bidLabel.BackgroundTransparency = 1
	bidLabel.Text = ""
	bidLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
	bidLabel.TextSize = 10
	bidLabel.Font = Enum.Font.Code
	bidLabel.TextXAlignment = Enum.TextXAlignment.Left
	bidLabel.Parent = card

	-- Aggressivity bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -16, 0, 5)
	barBg.Position = UDim2.new(0, 8, 0, 62)
	barBg.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 2)

	-- Aggressivity bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0.5, 0, 1, 0) -- updated at runtime
	barFill.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 2)

	npcCards[npcName] = card
	return card
end

-- ══════════════════════════════════════════
-- UPDATE LOGIC
-- ══════════════════════════════════════════

local function updateCard(card, npcData, auctionData)
	local status = card:FindFirstChild("StatusLabel")
	local stats = card:FindFirstChild("StatsLabel")
	local bidLbl = card:FindFirstChild("BidLabel")
	local barFill = card:FindFirstChild("BarBg") and card.BarBg:FindFirstChild("BarFill")

	-- Determine current winner name
	local winnerName = ""
	if auctionData and auctionData.currentBidder then
		local t = typeof(auctionData.currentBidder)
		winnerName = t == "Instance" and auctionData.currentBidder.Name or auctionData.currentBidder.name
	end

	local isWinning = winnerName == npcData.name

	-- Status badge
	if isWinning then
		status.Text = "WINNING"
		status.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
		status.TextColor3 = Color3.fromRGB(100, 230, 130)
	elseif npcData.isThinking then
		status.Text = "THINKING"
		status.BackgroundColor3 = Color3.fromRGB(90, 70, 20)
		status.TextColor3 = Color3.fromRGB(255, 200, 60)
	elseif npcData.balance < 200 then
		status.Text = "BROKE"
		status.BackgroundColor3 = Color3.fromRGB(90, 25, 25)
		status.TextColor3 = Color3.fromRGB(230, 80, 80)
	else
		status.Text = "IDLE"
		status.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		status.TextColor3 = Color3.fromRGB(120, 120, 150)
	end

	-- Stats row
	stats.Text = string.format("bal $%d  |  aggro %d%%", npcData.balance, npcData.aggressivity)

	-- Bid intent row
	if npcData.isThinking and npcData.targetBid and npcData.nextBidTime then
		local timeLeft = math.max(0, npcData.nextBidTime - os.clock())
		bidLbl.Text = string.format("→ bidding $%d in %.1fs", npcData.targetBid, timeLeft)
	elseif isWinning then
		bidLbl.Text = string.format("→ holding at $%d", auctionData and auctionData.currentBid or 0)
	else
		bidLbl.Text = "→ watching"
	end

	-- Aggressivity bar
	if barFill then
		barFill.Size = UDim2.new(npcData.aggressivity / 100, 0, 1, 0)
	end
end

local function updateAuctionInfo(auctionData)
	if not auctionData or not auctionData.started then
		auctionText.Text = "No active auction."
		auctionText.TextColor3 = Color3.fromRGB(120, 120, 140)
		return
	end

	local endTime = auctionData.startTime + auctionData.duration
	local remaining = math.max(0, endTime - os.clock())

	local bidderName = "Nobody"
	if auctionData.currentBidder then
		local t = typeof(auctionData.currentBidder)
		bidderName = t == "Instance" and auctionData.currentBidder.Name or auctionData.currentBidder.name
	end

	local itemName = (type(auctionData.item) == "table" and auctionData.item.Name) or "?"

	auctionText.Text = string.format(
		"item:    %s\nbid:     $%d  (%s)\ntime:    %.0fs remaining\navg:     $%d",
		itemName,
		auctionData.currentBid,
		bidderName,
		remaining,
		auctionData.averagePrice or 0
	)
	auctionText.TextColor3 = Color3.fromRGB(160, 220, 160)
end

-- ══════════════════════════════════════════
-- RECEIVE NPC SNAPSHOTS FROM SERVER
-- ══════════════════════════════════════════

-- The server needs to fire npc data alongside auction updates.
-- In your server loop, change UpdateAllClients to also send NPC info:
--
--   AuctionEvent:FireAllClients("update", self.Auction, NPCSystem.ActiveNPCs)
--
-- This script reads the optional third argument:

local lastNPCData = {}

AuctionEvent.OnClientEvent:Connect(function(action, auctionData, npcData)
	if action ~= "update" then return end
	currentAuction = auctionData
	if npcData then lastNPCData = npcData end
end)

-- ══════════════════════════════════════════
-- HEARTBEAT RENDER LOOP
-- ══════════════════════════════════════════

RunService.Heartbeat:Connect(function()
	updateAuctionInfo(currentAuction)

	for _, npcData in ipairs(lastNPCData) do
		local card = getOrCreateCard(npcData.name)
		updateCard(card, npcData, currentAuction)
	end
end)

-- ══════════════════════════════════════════
-- TOGGLE
-- ══════════════════════════════════════════

local collapsed = false
toggleBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	scrollFrame.Visible = not collapsed
	auctionFrame.Visible = not collapsed
	npcSectionLabel.Visible = not collapsed
	mainFrame.Size = collapsed and UDim2.new(0, 340, 0, 36) or UDim2.new(0, 340, 0, 500)
	toggleBtn.Text = collapsed and "SHOW" or "HIDE"
end)