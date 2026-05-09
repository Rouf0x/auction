local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)

ModuleLoader.__init(script:GetChildren())
ModuleLoader._Start()