---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local CharacterNames = Lua.import('Module:CharacterNames', {loadData = true})
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

local DEFAULT_BESTOF = 3
MatchFunctions.DEFAULT_MODE = 'team'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

--
-- match related functions
--

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(Logic.emptyOr(bestofInput, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestof)
	return bestof or DEFAULT_BESTOF
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

--
-- map related functions
--

---@param props {walkover: string|integer?, winner: string|integer?, score: string|integer?, opponentIndex: integer}
---@param autoScore? fun(opponentIndex: integer): integer?
---@return integer? #SCORE
---@return string? #STATUS
function MapFunctions.computeOpponentScore(props, autoScore)
	if props.score then
		props.score = props.score:gsub('m', '')
	end

	return MatchGroupInputUtil.computeOpponentScore(props, autoScore)
end


---@param match table
---@param game table
---@param opponents table[]
---@return table?
function MapFunctions.getExtraData(match, game, opponents)
	local banStart = tonumber(game.banstart)
	assert(banStart == 1 or banStart == 2 or not banStart, 'Invalid "|banstart="')

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterNames)
	return {
		team1ban1 = getCharacterName(game.t1b1),
		team2ban1 = getCharacterName(game.t2b1),
		banstart = banStart,
	}
end

return CustomMatchGroupInput
