---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MapFunctions = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		applyUnderScores = true,
		maxNumPlayers = 3,
	},
	DEFAULT_MODE = 'team'
}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessFfaMatch(match, MatchFunctions)
end

--
-- match related functions
--
---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function MatchFunctions.extractMaps(match, opponents, scoreSettings)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		Table.mergeInto(map, MatchGroupInputUtil.readDate(map.date))
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		map.opponents = Array.map(opponents, function(matchOpponent)
			local opponentMapInput = Json.parseIfString(matchOpponent['m' .. mapIndex])
			return MapFunctions.makeMapOpponentDetails(opponentMapInput, scoreSettings)
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		map.extradata = MapFunctions.getExtraData(map)

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param opponents table[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function MatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		scoring = settings.score,
		status = settings.status,
		settings = settings.settings,
	}
end

--
-- map related functions
--

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		dateexact = map.dateexact,
		comment = map.comment,
	}
end

---@param scoreDataInput table?
---@param scoreSettings table
---@return table
function MapFunctions.makeMapOpponentDetails(scoreDataInput, scoreSettings)
	if not scoreDataInput then
		return {}
	end

	local scoreBreakdown = {}

	local placement, kills = tonumber(scoreDataInput[1]), tonumber(scoreDataInput[2])
	if placement or kills then
		if placement then
			scoreBreakdown.placePoints = scoreSettings.placement[placement] or 0
		end
		if kills then
			scoreBreakdown.killPoints = kills * scoreSettings.kill
			scoreBreakdown.kills = kills
		end
		scoreBreakdown.totalPoints = (scoreBreakdown.placePoints or 0) + (scoreBreakdown.killPoints or 0)
	end
	local opponent = {
		status = MatchGroupInputUtil.STATUS.SCORE,
		scoreBreakdown = scoreBreakdown,
		placement = placement,
		score = scoreBreakdown.totalPoints,
	}

	if scoreDataInput[1] == '-' then
		opponent.status = MatchGroupInputUtil.STATUS.FORFEIT
		opponent.score = 0
	end

	return opponent
end

return CustomMatchGroupInput
