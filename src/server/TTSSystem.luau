--!strict
local TTSSystem = {}
TTSSystem.__index = TTSSystem
local SoundService = game:GetService("SoundService")
export type TTSSystem = typeof(setmetatable({}, TTSSystem))

type QueueEntry = {
	text: string,
	voice: string,
	speed: number,
	pitch: number,
	volume: number,
}

function TTSSystem:SetupSound(): ()
	local ADO = SoundService:FindFirstChildOfClass("AudioDeviceOutput")

	if not ADO then
		ADO = Instance.new("AudioDeviceOutput")
		ADO.Name = "TTSAudioDeviceOutput"
		ADO.Parent = SoundService
	end
	local Wire = Instance.new("Wire")
	Wire.Name = "TTSWire"
	Wire.Parent = SoundService
	self.Wire = Wire :: Wire
	self.Ado = ADO :: AudioDeviceOutput
end

function TTSSystem.Start()
	print("TTS System Started")
end

function TTSSystem.new(): TTSSystem
	local self = setmetatable({}, TTSSystem)
	self.voice = nil :: any?
	self.text = ""
	self.Ado = nil :: AudioDeviceOutput?
	self.Wire = nil :: Wire?
	self._pending = nil :: QueueEntry?
	self._speaking = false
	self:SetupSound()
	return self
end

function TTSSystem:CreateTTSInstance(): (AudioTextToSpeech?)
	if not self.Wire then
		self:SetupSound()
	end
	if not self.Ado then
		warn("AudioDeviceOutput not found")
		return nil
	end
	local TTSInstance = Instance.new("AudioTextToSpeech")
	TTSInstance.Parent = self.Wire

	local wire = self.Wire :: Wire
	local ado = self.Ado :: AudioDeviceOutput
	wire.TargetInstance = ado
	wire.SourceInstance = TTSInstance
	return TTSInstance
end

function TTSSystem:_processNext(): ()
	local entry = self._pending :: QueueEntry
	if not entry then
		return
	end

	self._pending = nil
	self._speaking = true

	local wire = Instance.new("Wire")
	wire.Parent = SoundService
	local TTSInstance = Instance.new("AudioTextToSpeech")
	TTSInstance.Parent = wire
	wire.TargetInstance = self.Ado :: AudioDeviceOutput
	wire.SourceInstance = TTSInstance
	TTSInstance.Text = entry.text
	TTSInstance.VoiceId = entry.voice
	TTSInstance.Speed = entry.speed
	TTSInstance.Pitch = entry.pitch
	TTSInstance.Volume = entry.volume
	TTSInstance:Play()

	TTSInstance.Ended:Connect(function()
		task.wait(1)
		TTSInstance:Destroy()
		wire:Destroy()
		self._speaking = false
		self:_processNext()
	end)
end

function TTSSystem:Speak(text: string, voice: string, speed: number, pitch: number, volume: number): ()
	self._pending = {
		text = text,
		voice = voice,
		speed = speed,
		pitch = pitch,
		volume = volume,
	}
	if not self._speaking then
		self:_processNext()
	end
end

return TTSSystem