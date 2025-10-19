---
-- @Liquipedia
-- page=Module:CharacterStats/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local BaseCharacterStats = Lua.import('Module:CharacterStats')
local Class = Lua.import('Module:Class')

local CharacterStatsWidget = Lua.import('Module:Widget/CharacterStats')

---@class HoKCharacterStats: CharacterStats
---@operator call(table): HoKCharacterStats
local HoKCharacterStats = Class.new(BaseCharacterStats)

---@return string[]
function HoKCharacterStats:getSides()
	return {'blue', 'red'}
end

---@param frame Frame
---@return Widget
function HoKCharacterStats.run(frame)
	local stats = HoKCharacterStats(Arguments.getArgs(frame))

	local conditions = stats:buildConditions()
	local matchIds = stats:getMatchIds(conditions)
	local games = stats:queryGames(matchIds)
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Hero',
		data = processedData.characterData,
		includeBans = true,
		numGames = #games,
		sides = stats:getSides(),
		sideWins = processedData.overall.wins,
	}
end

return HoKCharacterStats
