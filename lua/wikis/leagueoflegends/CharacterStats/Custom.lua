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

---@class LoLCharacterStats: CharacterStats
---@operator call(table): LoLCharacterStats
local LoLCharacterStats = Class.new(BaseCharacterStats)

---@return string[]
function LoLCharacterStats:getSides()
	return {'blue', 'red'}
end

---@param frame Frame
---@return Widget
function LoLCharacterStats.run(frame)
	local stats = LoLCharacterStats(Arguments.getArgs(frame))

	local conditions = stats:buildConditions()
	local matchIds = stats:getMatchIds(conditions)
	local games = stats:queryGames(matchIds)
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Champion',
		data = processedData.characterData,
		includeBans = true,
		numGames = #games,
		sides = stats:getSides(),
		sideWins = processedData.overall.wins,
	}
end

return LoLCharacterStats
