--!strict
local NotificationSystem = {}

type NotificationType = "info" | "warning" | "error"

type NotificationInstance = CanvasGroup & {
	MessageLabel: TextLabel,
	Type: ImageLabel
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Events = ReplicatedStorage:WaitForChild("Events")
local NotificationEvent = Events:WaitForChild("NotifyEvent")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer :: Player

local NotificationGui = Player.PlayerGui:WaitForChild("NotificationGui")
local NotificationTemplate = NotificationGui:WaitForChild("NotificationTemplate") :: NotificationInstance

local TypeImages: { [NotificationType]: string } = {
	["info"] = "rbxassetid://17829955945",
	["warning"] = "rbxassetid://10030878948",
	["error"] = "rbxassetid://5107154082",
}

local POP_IN = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

function ShowNotification(NotificationMessage: string, type: NotificationType, duration: number)
	duration = duration or 3
	
	local Notification = NotificationTemplate:Clone() :: NotificationInstance
	local TargetSize = NotificationTemplate.Size

	local infoType: NotificationType = "info"
	local finalType: NotificationType = if TypeImages[type] then type else infoType

	Notification.GroupTransparency = 1
	Notification.Size = UDim2.fromScale(TargetSize.X.Scale * 0.5, TargetSize.Y.Scale * 0.5)
	Notification.MessageLabel.Text = NotificationMessage

	Notification.Type.Image = TypeImages[finalType]

	Notification.Parent = NotificationGui
	Notification.Visible = true

	TweenService:Create(Notification, POP_IN, {
		GroupTransparency = 0,
		Size = TargetSize
	}):Play()

	task.delay(duration, function()
		local fadeOut = TweenService:Create(Notification, SLIDE_OUT, {
			GroupTransparency = 1,
			Position = Notification.Position + UDim2.fromScale(0.2, 0),
			Size = UDim2.fromScale(TargetSize.X.Scale * 0.8, TargetSize.Y.Scale * 0.8)
		})

		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			Notification:Destroy()
		end)
	end)
end

function NotificationSystem.Start()
	print('Notification System Started')
	NotificationEvent.OnClientEvent:Connect(ShowNotification)
end

return NotificationSystem