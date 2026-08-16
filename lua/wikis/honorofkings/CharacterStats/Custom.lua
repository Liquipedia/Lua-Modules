---
-- @Liquipedia
-- page=Module:CharacterStats/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BaseCharacterStats = Lua.import('Module:CharacterStats')

local CharacterStatsWidget = Lua.import('Module:Widget/CharacterStats')

local HoKCharacterStats = {}

---@return string[]
function BaseCharacterStats.getSides()
	return {'blue', 'red'}
end

---@param frame Frame
---@return Widget
function HoKCharacterStats.run(frame)
	local args = Arguments.getArgs(frame)

	local games = BaseCharacterStats.queryGames(args)
	local processedData = BaseCharacterStats.processGames(games)
	return CharacterStatsWidget{
		characterType = 'Hero',
		data = processedData.characterData,
		includeBans = Array.any(processedData.characterData, function (data)
			return data.bans > 0
		end),
		numGames = #games,
		sides = BaseCharacterStats.getSides(),
		sideWins = processedData.overall.wins,
		statspage = args.statspage
	}
end

return HoKCharacterStats
