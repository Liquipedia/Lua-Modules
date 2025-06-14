---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Operator = require('Module:Operator')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local SIDE_DEF = 'ct'
local SIDE_ATK = 't'

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

local CustomMatchGroupInput = {}

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
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
	}
end

--
-- map related functions
--

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return MapFunctions.getSideData(map)
end

---@param map table
---@return table
function MapFunctions.getSideData(map)
	---@param sideInput string
	---@return boolean
	local isValidSide = function(sideInput)
		return Logic.isNotEmpty(sideInput) and (sideInput == SIDE_DEF or sideInput == SIDE_ATK)
	end

	---@param prefix string
	---@param t1Side string
	---@param t2Side string
	---@return {t1Side: string, t2Side: string, t1Half: integer, t2Half: integer}?
	local getDataFor = function(prefix, t1Side, t2Side)
		local half1 = tonumber(map[prefix .. 't1' .. t1Side])
		local half2 = tonumber(map[prefix .. 't2' .. t2Side])
		if not half1 or not half2 then return end
		return {
			t1Side = t1Side,
			t2Side = t2Side,
			t1Half = half1,
			t2Half = half2,
		}
	end

	---@param prefix string
	---@return {t1Side: string, t2Side: string, t1Half: integer, t2Half: integer}[]?
	local getSideData = function(prefix)
		local t1Side = map[prefix .. 't1firstside']
		if not isValidSide(t1Side) then return end
		local t2Side = t1Side == SIDE_DEF and SIDE_ATK or SIDE_DEF

		return Array.append({},
			getDataFor(prefix, t1Side, t2Side),
			getDataFor(prefix, t2Side, t1Side)
		)
	end

	local sideData = getSideData('') or {}

	Array.extendWith(sideData, Array.mapIndexes(function(overtimeIndex)
		return getSideData('o' .. overtimeIndex)
	end))

	return {
		t1sides = Array.map(sideData, Operator.property('t1Side')),
		t2sides = Array.map(sideData, Operator.property('t2Side')),
		t1halfs = Array.map(sideData, Operator.property('t1Half')),
		t2halfs = Array.map(sideData, Operator.property('t2Half')),
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local sideData = MapFunctions.getSideData(map)
	return function(opponentIndex)
		local partialScores = sideData['t' .. opponentIndex .. 'halfs']
		if Logic.isEmpty(partialScores) then
			return
		end

		return MathUtil.sum(partialScores)
	end
end

return CustomMatchGroupInput
