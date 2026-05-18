
--[[local ServerScriptService = game:GetService("ServerScriptService")

local TTSSystemModule = require(ServerScriptService.Server.TTSSystem)

-- Create a new instance of the TTS system
local tts = TTSSystemModule.new()
task.wait(10)
print("yapping")

local textToSay = "Hello world! The text to speech system is working perfectly."
local voiceType = "1"    -- Represents the voice ID enum/index
local speed = 1.5      -- Normal speed
local pitch = 0.8      -- Normal pitch
local volume = 1.0     -- Full volume

-- Make it speak
tts:Speak(textToSay, voiceType, speed, pitch, volume)]]--