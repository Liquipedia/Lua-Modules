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
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

MatchFunctions.DEFAULT_MODE = '2v2'
MatchFunctions.DATE_FALLBACKS = {'tournament_enddate'}
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

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
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if not map.map then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
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
---@return table
function MatchFunctions.getExtraData(match)
	local opponent1 = match.opponent1 or {}
	local opponent2 = match.opponent2 or {}

	return {
		isfeatured = MatchFunctions.isFeatured(match),
		casters = MatchGroupInputUtil.readCasters(match),
		hasopponent1 = Logic.isNotEmpty(opponent1.name) and opponent1.type ~= Opponent.literal,
		hasopponent2 = Logic.isNotEmpty(opponent2.name) and opponent2.type ~= Opponent.literal,
	}
end

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
		overtime = Logic.readBool(map.overtime)
	}
end

return CustomMatchGroupInput
