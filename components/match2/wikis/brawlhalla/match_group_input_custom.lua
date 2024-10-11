---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardization = mw.loadData('Module:CharacterStandardization')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local CustomMatchGroupInput = {}


-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date, {
		'tournament_enddate',
		'tournament_startdate',
	})))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, opponents)
	match.bestof = MatchGroupInputUtil.getBestOf(nil, games)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and CustomMatchGroupInput.calculateMatchScore(games)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
		match.winner = MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))
	match.mode = Variables.varDefault('tournament_mode', 'singles')

	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	return match
end

---@param match table
---@param matchOpponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, matchOpponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if String.isNotEmpty(map.map) and map.map ~= 'TBD' then
			map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map)
		end

		map.extradata = {
			comment = map.comment,
		}
		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		map.opponents = Array.map(matchOpponents, function(opponent, opponentIndex)
			return CustomMatchGroupInput.getParticipantsOfOpponent(map, opponent, opponentIndex)
		end)

		local opponentInfo = Array.map(matchOpponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, CustomMatchGroupInput.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table<string, table>?
function CustomMatchGroupInput.getParticipantsOfOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.solo then
		return CustomMatchGroupInput._processSoloMapData(opponent.match2players[1], map, opponentIndex)
	end
	return nil
end

---@param player table
---@param map table
---@param opponentIndex integer
---@return table<string, table>
function CustomMatchGroupInput._processSoloMapData(player, map, opponentIndex)
	local char = map['char' .. opponentIndex] or ''

	return {
		players = {
			{
				char = MatchGroupInputUtil.getCharacterName(CharacterStandardization, char),
				player = player.name,
			}
		}
	}
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInput.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
