---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterNames = require('Module:CharacterNames')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@type table<string, {flipForDef: boolean, numberOfBansPerTeam: integer}>
local OPERATOR_BAN_FORMATS = {
	['atk,def'] = {flipForDef = false, numberOfBansPerTeam = 2}, -- before siegeX
	['atk,atk,atk,def,def,def'] = {flipForDef = true, numberOfBansPerTeam = 6}, -- since siegeX
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
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
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
---@param opponents table[]
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

-- Parse extradata information, particularally info about halfs and operator bans
---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		t1firstside = {rt = map.t1firstside, ot = map.t1firstsideot},
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}

	-- temp workaround until bot job is done
	local banTypeInput = map.bantype or 'atk,def'
	local operatorBanFormatInfo = OPERATOR_BAN_FORMATS[banTypeInput]
	-- local operatorBanFormatInfo = OPERATOR_BAN_FORMATS[map.bantype]
	assert(operatorBanFormatInfo, 'Invalid input: "|bantype=' .. (map.bantype or '') .. '"')

	local banTypes = Array.parseCommaSeparatedString(map.bantype)
	local banReverseIndex = function(opponentIndex)
		local indexToPotentiallyFlip = map.t1firstside == 'atk' and 2
			or map.t1firstside == 'def' and 1
		return operatorBanFormatInfo.flipForDef and opponentIndex == indexToPotentiallyFlip
	end

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterNames)
	Array.forEach(opponents, function(_, opponentIndex)
		local prefix = 't' .. opponentIndex
		extradata[prefix .. 'bans'] = Array.map(Array.range(1, operatorBanFormatInfo.numberOfBansPerTeam), function(banIndex)
			local ban = map[prefix .. 'ban' .. banIndex]
			return getCharacterName(ban) or ''
		end)

		extradata[prefix .. 'bantypes'] = banReverseIndex(opponentIndex) and Array.reverse(banTypes) or Table.copy(banTypes)
	end)

	return extradata
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'atk'] and not map['t'.. opponentIndex ..'def'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'atk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'def']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otatk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otdef']) or 0)
	end
end

return CustomMatchGroupInput
