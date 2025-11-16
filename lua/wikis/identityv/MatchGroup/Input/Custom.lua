---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterNames = Lua.import('Module:CharacterNames')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local MAX_NUM_BANS = 6
local MAX_NUM_PICKS = 5
local VALID_SIDES = {
	'hunter',
	'survivor',
}

MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

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
		return map.map ~= nil or Logic.readBool(map.finished) or map.t1survivor or map.t1hunter or map.score1
	end)
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

-- Parse extradata information, particularally info about halfs and operator bans and picks
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
		t1halfs = {hunter = map.t1hunter, survivor = map.t1survivor},
		t2halfs = {hunter = map.t2hunter, survivor = map.t2survivor},
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterNames)

	Array.forEach(opponents, function(_, opponentIndex)
		local prefix = 't' .. opponentIndex
		extradata[prefix .. 'bans'] = Array.map(Array.range(1, MAX_NUM_BANS), function(banIndex)
			return getCharacterName(map[prefix .. 'ban' .. banIndex]) or ''
		end)
		extradata[prefix .. 'picks'] = Array.map(Array.range(1, MAX_NUM_PICKS), function(pickIndex)
			return getCharacterName(map[prefix .. 'pick' .. pickIndex]) or ''
		end)
	end)

	return extradata
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'hunter'] and not map['t'.. opponentIndex ..'survivor'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'hunter']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'survivor']) or 0)
	end
end

return CustomMatchGroupInput
