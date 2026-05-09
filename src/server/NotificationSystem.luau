--!strict
local NotificationSystem = {}

export type NotificationData = {
	message: string,
	type: ("info" | "warning" | "error")?,
	duration: number?
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationEvent = ReplicatedStorage.Events.NotifyEvent :: RemoteEvent

function NotificationSystem.Start()
	print('Notification System Started')
end

function NotificationSystem.Notify(player: Player, data: NotificationData)
	if not player or not player:IsA("Player") then
		error('Invalid player!')
	end
	
	if not data.duration then
		error('Notification duration is nil!')
	end
	
	local MessageType = data.type or "info"
	
	NotificationEvent:FireClient(player, data.message, MessageType, data.duration)
end

return NotificationSystem