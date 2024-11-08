---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

local DEFAULT_BESTOF = 3
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
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
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.map = MapFunctions.getMapName(map)
		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		map.opponents = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {
				score = score,
				status = status,
				time = map.extradata.times[opponentIndex],
				percentage = map.extradata.percentages[opponentIndex] or 0
			}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput)

	if bestof then
		Variables.varDefine('bestof', bestof)
		return bestof
	end

	return tonumber(Variables.varDefault('bestof')) or DEFAULT_BESTOF
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

--
-- map related functions
--
---@param map table
---@return string?
function MapFunctions.getMapName(map)
	return nil
end

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
		times = MapFunctions.readTimes(map),
		percentages = MapFunctions.readPercentages(map),
	}
end

---@param map table
---@return table
function MapFunctions.readPercentages(map)
	local percentages = {}

	for _, percentage in Table.iter.pairsByPrefix(map, 'percent') do
		table.insert(percentages, tonumber(percentage) or 0)
	end

	return percentages
end

---@param map table
---@return table
function MapFunctions.readTimes(map)
	local timesInSeconds = {}

	for _, timeInput in Table.iter.pairsByPrefix(map, 'time') do
		local timeFragments = Array.map(
			Array.reverse(mw.text.split(timeInput, ':', true)),
			function(number, index)
				number = tonumber(number)
				return number and ((60 ^ (index - 1)) * number) or number
			end
		)

		table.insert(timesInSeconds, MathUtil.sum(timeFragments))
	end

	return timesInSeconds
end

return CustomMatchGroupInput
