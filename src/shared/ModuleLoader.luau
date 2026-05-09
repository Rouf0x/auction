local ModuleLoader = {}
local CachedModules = {}

type Module = {
	Init: (any) -> (),
	Start: (any) -> (),
	[any]: any
}

function ModuleLoader.Get(name : string)
	local module = CachedModules[name]
	
	if not module then
		warn("Couldn't find module " .. name .."!")
	end
	return module
end

function ModuleLoader.__init(scripts : {ModuleScript})
	for _,modscript in scripts do
		if not modscript:IsA("ModuleScript") then continue end
		
		if CachedModules[modscript.Name] then
			error('Cannot have multiple module with the same name. '..modscript.Name..' already exists!')
		end
		
		local success, result = pcall(require, modscript)
		if not success then 
			warn("Failed to load module: " .. modscript.Name .. " Error: " .. result) 
			return
		end
		CachedModules[modscript.Name] = result
	end
end

function ModuleLoader._Start()
	for name, module in CachedModules do
		if type(module) ~= "table" or typeof(module.Start) ~= "function" then continue end
		
		local success, err = pcall(module.Start, module)
		if not success then
			warn("Failed to start module: " .. name .. " Error: " .. err)
		end
	end
end

return ModuleLoader
