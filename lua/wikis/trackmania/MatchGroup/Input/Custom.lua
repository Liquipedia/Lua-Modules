---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	DEFAULT_MODE = '2v2',
	DATE_FALLBACKS = {'tournament_enddate'},
	getBestOf = MatchGroupInputUtil.getBestOf,
}
local MapFunctions = {}

local FfaMatchFunctions = {
	DEFAULT_MODE = 'solo',
	DATE_FALLBACKS = {'tournament_enddate'},
}
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
end

--- Up to 4-opponents

---@param match table
---@param opponents table[]
---@return boolean
function MatchFunctions.switchToFfa(match, opponents)
	return #opponents > 4
end

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

---@param opponent MGIParsedOpponent
---@param opponentIndex integer
function MatchFunctions.adjustOpponent(opponent, opponentIndex)
	opponent.extradata = CustomMatchGroupInput.getOpponentExtradata(opponent)
	if opponent.extradata.additionalScores then
		opponent.score = CustomMatchGroupInput._getSetWins(opponent)
	end
end

---@param opponent table
---@return table
function CustomMatchGroupInput.getOpponentExtradata(opponent)
	if not Logic.isNumeric(opponent.score2) then
		return {}
	end

	return {
		score1 = tonumber(opponent.score),
		score2 = tonumber(opponent.score2),
		score3 = tonumber(opponent.score3),
		set1win = Logic.readBool(opponent.set1win),
		set2win = Logic.readBool(opponent.set2win),
		set3win = Logic.readBool(opponent.set3win),
		additionalScores = true
	}
end

---@param opponent table
---@return integer
function CustomMatchGroupInput._getSetWins(opponent)
	local setWin = function(setIndex)
		return opponent.extradata['set' .. setIndex .. 'win'] and 1 or 0
	end
	return setWin(1) + setWin(2) + setWin(3)
end

---@param match table
---@return boolean
function MatchFunctions.isFeatured(match)
	return tonumber(match.liquipediatier) == 1
		or tonumber(match.liquipediatier) == 2
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	local opponent1 = opponents[1] or {}
	local opponent2 = opponents[2] or {}

	return {
		isfeatured = MatchFunctions.isFeatured(match),
		hasopponent1 = Logic.isNotEmpty(opponent1.name) and opponent1.type ~= Opponent.literal,
		hasopponent2 = Logic.isNotEmpty(opponent2.name) and opponent2.type ~= Opponent.literal,
	}
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		overtime = Logic.readBool(map.overtime)
	}
end

--- FFA Match

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents table[]
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
