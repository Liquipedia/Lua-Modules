---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Variables = Lua.import('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_BESTOF = 3
local SIDE_ALIASES = {
	atk = 'ATK',
	def = 'DEF',
}

local CustomMatchGroupInput = {}

---@class DeltaforceMatchParser: MatchParserInterface
local MatchFunctions = {
	DEFAULT_MODE = 'team',
}

---@class DeltaforceMapParser: MapParserInterface
local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

---@class DeltaforceFfaMatchParser: FfaMatchParserInterface
local FfaMatchFunctions = {
	DEFAULT_MODE = 'team',
}

---@class DeltaforceFfaMapParser: FfaMapParserInterface
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
end

-- "Normal" match
---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('bestof'))

	if bestof then
		Variables.varDefine('bestof', bestof)
	end

	return bestof
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

---@param match table
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

-- Parse extradata information, particularally info about halfs and operator bans
---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	if Logic.isEmpty(map.team1side) then
		return {}
	end

	local t1side = map.team1side:upper()

	return t1side == 'ATK' and {
		t1side = 'ATK',
		t2side = 'DEF',
	} or t1side == 'DEF' and {
		t1side = 'DEF',
		t2side = 'ATK',
	} or error('Invalid side specified: "' .. map.team1side .. '"')
end

--- FFA Match

---@param match table
---@param opponents MGIParsedOpponent[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents MGIParsedOpponent[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FfaMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

return CustomMatchGroupInput
