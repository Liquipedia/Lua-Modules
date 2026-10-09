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
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
---@class Standoff2MatchParser: MatchParserInterface
local MatchFunctions = {
	DEFAULT_MODE = 'team',
	getBestOf = MatchGroupInputUtil.getBestOf,
}

---@class Standoff2MapParser: MapParserInterface
local MapFunctions = {}

local VALID_SIDES = {
	't',
	'ct',
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

--
-- match related functions
--

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil or Logic.readBool(map.finished) or map.t1t or map.t1ct or map.score1
	end)
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

--
-- map related functions
--

-- Parse extradata information, particularly info about halfs
---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	if Logic.isEmpty(map.t1firstside) then
		return {}
	end
	assert(Table.includes(VALID_SIDES, map.t1firstside), 'Invalid side input "|t1firstside=' .. map.t1firstside .. '"')
	local extradata = {
		t1firstside = map.t1firstside,
		t1halfs = {t = map.t1t, ct = map.t1ct},
		t2halfs = {t = map.t2t, ct = map.t2ct},
	}

	return extradata
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'t'] and not map['t'.. opponentIndex ..'ct'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'t']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'ct']) or 0)
	end
end

return CustomMatchGroupInput
