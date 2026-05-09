local DataSystem = {}

export type ItemData = {
	Name: string,
	Amount: number,
	Condition: string,
	Price: number,
	Description: string,
}

export type PlayerData = {
	Money: number,
	Inventory: { ItemData },
}

local DEFAULT_DATA: PlayerData = {
	Money = 0,
	Inventory = {},
}

DataSystem.Profiles = {} :: {[Player]: PlayerData}

function DataSystem.GetProfile(player: Player): PlayerData
	if not DataSystem.Profiles[player] then
		DataSystem.Profiles[player] = table.clone(DEFAULT_DATA)
	end
	return DataSystem.Profiles[player]
end

function DataSystem.RemoveProfile(player: Player)
	DataSystem.Profiles[player] = nil
end

return DataSystem
