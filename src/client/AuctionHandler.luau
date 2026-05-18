-- WARNING: THIS CANNOT HANDLE MULTIPLE AUCTIONS AT ONCE
-- MUST FIX NOW BUT IM TOO LAZY FFS

local AuctionHandler = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AuctionEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("AuctionEvent")

local SettedUpButtons = {}
local SettedUpDisplays = {}
local autoBid = true

local currentAuction = nil
local auctionEndAt = 0

AuctionEvent.OnClientEvent:Connect(function(action, auction, _npcs, serverEndAt)
	if action ~= "update" then
		return
	end
	currentAuction = auction
	auctionEndAt = serverEndAt
end)

local displayTexts = {}

RunService.Heartbeat:Connect(function()
	if #displayTexts == 0 then
		return
	end

	local text
	if not currentAuction or not currentAuction.started then
		text = "No Auction"
	else
		local remaining = math.max(0, auctionEndAt - os.clock())
		text = string.format(
			"-- Auction --\nItem: %s\nCurrent Bid: %d\nCurrent Bidder: %s\nTime Remaining: %.1f",
			currentAuction.item.Name,
			currentAuction.currentBid,
			currentAuction.currentBidderName,
			remaining
		)
	end

	for _, displayText in ipairs(displayTexts) do
		displayText.Text = text
	end
end)

local function SetupDisplay(display)
	if SettedUpDisplays[display] then
		return
	end
	SettedUpDisplays[display] = true

	local gui = display:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	if not label then
		warn("Incorrect Setup: ", display)
		return
	end

	table.insert(displayTexts, label)
end

local function SetupButton(bidButton)
	if SettedUpButtons[bidButton] then
		return
	end
	SettedUpButtons[bidButton] = true

	local bidAmountPart = bidButton:FindFirstChild("BidAmount")
	local clickDetector = bidButton:FindFirstChildOfClass("ClickDetector")
	if not bidAmountPart or not clickDetector then
		warn("Incorrect Setup: ", bidButton)
		return
	end

	local gui = bidAmountPart:FindFirstChildOfClass("SurfaceGui")
	local field = gui and gui:FindFirstChildOfClass("TextBox")
	if not field then
		warn("Incorrect Setup: ", bidButton)
		return
	end

	clickDetector.MouseClick:Connect(function()
		if not currentAuction or not currentAuction.started then
			return
		end
		if autoBid then
			AuctionEvent:FireServer("bid", math.floor(currentAuction.currentBid * 1.2))
		else
			AuctionEvent:FireServer("bid", tonumber(field.Text) or 0)
		end
	end)
end

function AuctionHandler.Start()
	print("Auction Handler Started")
	for _, b in pairs(CollectionService:GetTagged("BidButton")) do
		SetupButton(b)
	end
	for _, d in pairs(CollectionService:GetTagged("AuctionDisplay")) do
		SetupDisplay(d)
	end
	CollectionService:GetInstanceAddedSignal("BidButton"):Connect(SetupButton)
	CollectionService:GetInstanceAddedSignal("AuctionDisplay"):Connect(SetupDisplay)
	AuctionEvent:FireServer("update")
end

return AuctionHandler