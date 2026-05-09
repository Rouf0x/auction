local AuctionHandler = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Events = ReplicatedStorage:WaitForChild("Events")
local AuctionEvent = Events:WaitForChild("AuctionEvent")
local SettedUpButtons = {}
local SettedUpDisplays = {}

local currentAuction = nil
local autoBid = true

function UpdateDisplay(displayText: TextLabel)
	AuctionEvent.OnClientEvent:Connect(function(action, auction)
		if action ~= "update" then return end
		currentAuction = auction
	end)
	RunService.Heartbeat:Connect(function()
		if not currentAuction or not currentAuction.started then
			displayText.Text = "No Auction"
			return
		end
		local endTime = currentAuction.startTime + currentAuction.duration
		local currentTime = os.clock()
		local remainingTime = math.max(0, endTime - currentTime)

		local bidderName = "Nobody"
		if currentAuction.currentBidder then
			bidderName = currentAuction.currentBidder.name
		end

		displayText.Text = string.format(
			"-- Auction --\n" ..
				"Item: %s\n" ..
				"Current Bid: %d\n" ..
				"Current Bidder: %s\n" ..
				"Time Remaining: %d\n",
			currentAuction.item.Name,
			currentAuction.currentBid,
			bidderName,
			remainingTime
		)
	end)
end

function SetupDisplay(display)
	if SettedUpDisplays[display] then return end
	SettedUpDisplays[display] = true
	local displayGui = display:FindFirstChildOfClass("SurfaceGui")
	local displayText = displayGui and displayGui:FindFirstChildOfClass("TextLabel")

	if not displayText then
		warn('Incorrect Setup: ', display)
		return
	end

	task.spawn(function()
		UpdateDisplay(displayText)
	end)
end

function Bid(amount)
	AuctionEvent:FireServer("bid", amount)
end

function SetupButton(bidButton)
	if SettedUpButtons[bidButton] then return end
	SettedUpButtons[bidButton] = true
	local bidAmountPart = bidButton:FindFirstChild("BidAmount")
	local clickDetector = bidButton:FindFirstChildOfClass("ClickDetector")

	if not bidAmountPart or not clickDetector then
		warn('Incorrect Setup: ', bidButton)
		return
	end

	local bidAmountGui = bidAmountPart:FindFirstChildOfClass("SurfaceGui")
	local bidAmountField = bidAmountGui and bidAmountGui:FindFirstChildOfClass("TextBox")

	if not bidAmountField then
		warn('Incorrect Setup: ', bidButton)
		return
	end
	
	clickDetector.MouseClick:Connect(function()
		if autoBid and currentAuction and currentAuction.started then
			local autoBidAmount = math.floor(currentAuction.currentBid * 1.2)
			Bid(autoBidAmount)
		else
			local bidAmount = tonumber(bidAmountField.Text) or 0
			Bid(bidAmount)
		end
	end)
end

function AuctionHandler.Start()
	print('Auction Handler Started')
	for _, button in pairs(CollectionService:GetTagged("BidButton")) do
		task.spawn(SetupButton, button)
	end
	for _, display in pairs(CollectionService:GetTagged("AuctionDisplay")) do
		task.spawn(SetupDisplay, display)
	end
	CollectionService:GetInstanceAddedSignal("BidButton"):Connect(SetupButton)
	CollectionService:GetInstanceAddedSignal("AuctionDisplay"):Connect(SetupDisplay)
	AuctionEvent:FireServer("update")
end

return AuctionHandler