---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		disregardTransferDates = true,
	}
}

MatchFunctions.DEFAULT_MODE = 'team'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	options = options or {}

	if not options.isMatchPage then
		-- See if this match has a standalone match (match page), if so use the data from there
		local standaloneMatchId = MatchGroupUtil.getStandaloneId(match.bracketid, match.matchid)
		local standaloneMatch = standaloneMatchId and MatchGroupInputUtil.fetchStandaloneMatch(standaloneMatchId) or nil
		if standaloneMatch then
			return MatchGroupInputUtil.mergeStandaloneIntoMatch(match, standaloneMatch)
		end
	end

	local MapParser
	if options.isMatchPage then
		MapParser = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
	else
		MapParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')
	end

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, nil, MapParser)
end

--
-- match related functions
--

---@param match table
---@param opponents MGIParsedOpponent[]
---@param MapParser MapParserInterface
---@return table[]
function MatchFunctions.extractMaps(match, opponents, MapParser)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapParser)
end

MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function (game) return game.map ~= nil end)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end



return CustomMatchGroupInput
