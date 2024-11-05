---
-- @Liquipedia
-- wiki=halo
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local DEFAULT_BESTOF = 3
MatchFunctions.DEFAULT_MODE = 'team'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local parsedMatch = MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
	parsedMatch.links.headtohead = MatchFunctions.getHeadToHeadLink(match, parsedMatch.opponents)
	return parsedMatch
end

--
-- match related functions
--

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

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
		casters = MatchGroupInputUtil.readCasters(match),
	}
end

---@param match table
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	if
		opponents[1].type ~= Opponent.team or
		opponents[2].type ~= Opponent.team or
		not opponents[1].name or
		not opponents[2].name then

		return nil
	end

	local team1, team2 = string.gsub(opponents[1].name, ' ', '_'), string.gsub(opponents[2].name, ' ', '_')
	local buildQueryFormLink = function(form, template, arguments)
		return tostring(mw.uri.fullUrl('Special:RunQuery/' .. form,
			mw.uri.buildQueryString(Table.map(arguments, function(key, value) return template .. key, value end))
				.. '&_run'
		))
	end

	local headtoheadArgs = {
		['[team1]'] = team1,
		['[team2]'] = team2,
		['[games][is_list]'] = 1,
		['[tiers][is_list]'] = 1,
		['[fromdate][day]'] = '01',
		['[fromdate][month]'] = '01',
		['[fromdate][year]'] = string.sub(match.date,1,4)
	}

	return buildQueryFormLink('Head2head', 'Headtohead', headtoheadArgs)
end

--
-- map related functions
--

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
		points1 = map.points1,
		points2 = map.points2,
	}
end

return CustomMatchGroupInput
