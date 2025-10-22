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
local Class = Lua.import('Module:Class')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

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
	local args = Arguments.getArgs(frame)
	local stats = HoKCharacterStats(args)

	local matchIds = MatchGroupUtil.fetchMatchIds{
		conditions = stats:buildConditions(),
		limit = 5000,
	}
	local games = stats:queryGames(matchIds)
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Hero',
		data = processedData.characterData,
		includeBans = Array.any(processedData.characterData, function (data)
			return data.bans > 0
		end),
		numGames = #games,
		sides = stats:getSides(),
		sideWins = processedData.overall.wins,
		statspage = args.statspage
	}
end

return HoKCharacterStats
