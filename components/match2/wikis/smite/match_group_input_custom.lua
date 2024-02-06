---
-- @Liquipedia
-- wiki=smite
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local HeroNames = mw.loadData('Module:GodNames')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local STATUS_SCORE = 'S'
local STATUS_DRAW = 'D'
local STATUS_DEFAULT_WIN = 'W'
local STATUS_FORFEIT = 'FF'
local STATUS_DISQUALIFIED = 'DQ'
local STATUS_DEFAULT_LOSS = 'L'
local _ALLOWED_STATUSES = {
	STATUS_DRAW,
	STATUS_DEFAULT_WIN,
	STATUS_FORFEIT,
	STATUS_DISQUALIFIED,
	STATUS_DEFAULT_LOSS,
}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 15
local MAX_NUM_GAMES = 7
local DEFAULT_MODE = 'team'
local NO_SCORE = -99
local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local DEFAULT_RESULT_TYPE = 'default'
local NOT_PLAYED_SCORE = -1
local NO_WINNER = -1
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getScoreFromMapWinners(match)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)

	-- Adjust map data, especially set participants data
	match = matchFunctions.adjustMapData(match)

	return match
end

function matchFunctions.adjustMapData(match)
	local opponents = {}
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		opponents[opponentIndex] = match['opponent' .. opponentIndex]
	end
	local mapIndex = 1
	while match['map'..mapIndex] do
		match['map'..mapIndex] = mapFunctions.getParticipants(match['map'..mapIndex], opponents)
		mapIndex = mapIndex + 1
	end

	return match
end

-- called from Module:Match/Subobjects
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getScoresAndWinner(map)

	return map
end

---@param record table
---@param date string
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type number|string
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
---@param player table
---@return table
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
-- function to check for draws
--
function CustomMatchGroupInput.placementCheckDraw(scoreTable)
	local last
	for _, scoreInfo in pairs(scoreTable) do
		if scoreInfo.status ~= STATUS_SCORE and scoreInfo.status ~= STATUS_DRAW then
			return false
		end
		if last and last ~= scoreInfo.score then
			return false
		else
			last = scoreInfo.score
		end
	end

	return true
end

function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if
		Table.includes(NP_STATUSES, data.finished) or
		Table.includes(NP_STATUSES, data.winner)
	then
		data.resulttype = 'np'
		data.finished = true
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if CustomMatchGroupInput.placementCheckDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 'draw')
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = CustomMatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = DEFAULT_RESULT_TYPE
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, DEFAULT_RESULT_TYPE)
		else
			local winner
			indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, nil, data.finished)
			data.winner = data.winner or winner
		end
	end

	-- set it as finished if we have a winner
	if not Logic.isEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

function CustomMatchGroupInput.setPlacement(opponents, winner, specialType, finished)
	if specialType == STATUS_DRAW then
		for key in pairs(opponents) do
			opponents[key].placement = 1
		end
	elseif specialType == DEFAULT_RESULT_TYPE then
		for key in pairs(opponents) do
			if key == winner then
				opponents[key].placement = 1
			else
				opponents[key].placement = 2
			end
		end
	else
		local lastScore = NO_SCORE
		local lastPlacement = NO_SCORE
		local counter = 0
		for scoreIndex, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.placementSortFunction) do
			local score = tonumber(opp.score)
			counter = counter + 1
			if counter == 1 and String.isEmpty(winner) then
				if finished then
					winner = scoreIndex
				end
			end
			if lastScore == score then
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or lastPlacement
			else
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or counter
				lastPlacement = counter
				lastScore = score or NO_SCORE
			end
		end
	end

	return opponents, winner
end

function CustomMatchGroupInput.placementSortFunction(table, key1, key2)
	local value1 = tonumber(table[key1].score or NO_SCORE) or NO_SCORE
	local value2 = tonumber(table[key2].score or NO_SCORE) or NO_SCORE
	return value1 > value2
end

-- Check if any opponent has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(table)
	return Table.any(table,
		function (_, scoreinfo)
			return scoreinfo.status ~= STATUS_SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == STATUS_FORFEIT end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == STATUS_DISQUALIFIED end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == STATUS_DEFAULT_LOSS end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(table)
	for index, scoreInfo in pairs(table) do
		if scoreInfo.status == STATUS_DEFAULT_WIN then
			return index
		end
	end
	return NO_WINNER
end

--
-- match related functions
--
function matchFunctions.getBestOf(match)
		match.bestof = #Array.filter(Array.range(1, MAX_NUM_GAMES), function(idx) return match['map'.. idx] end)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update an opponents result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	local newScores = {}
	local setScores = false

	-- If the match has started, we want to use the automatic calculations
	if match.dateexact then
		if match.timestamp <= NOW then
			setScores = true
		end
	end

	local mapIndex = 1
	while match['map'..mapIndex] do
		local winner = tonumber(match['map'..mapIndex].winner)
		if winner and winner > 0 and winner <= MAX_NUM_OPPONENTS then
			setScores = true
			newScores[winner] = (newScores[winner] or 0) + 1
		end
		mapIndex = mapIndex + 1
	end

	for index = 1, MAX_NUM_OPPONENTS do
		if not match['opponent' .. index].score and setScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	return match
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- apply status
			opponent.score = string.upper(opponent.score or '')
			if Logic.isNumeric(opponent.score) then
				opponent.score = tonumber(opponent.score)
				opponent.status = STATUS_SCORE
				isScoreSet = true
			elseif Table.includes(_ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = NOT_PLAYED_SCORE
			end

			-- get players from vars for teams
			if opponent.type == Opponent.team then
				if not Logic.isEmpty(opponent.name) then
					match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
						resolveRedirect = true,
						applyUnderScores = true,
						maxNumPlayers = MAX_NUM_PLAYERS,
					})
				end
			elseif opponent.type == Opponent.solo then
				opponent.match2players = Json.parseIfString(opponent.match2players) or {}
				opponent.match2players[1].name = opponent.name
			elseif opponent.type ~= Opponent.literal then
				error('Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
			end

			opponents[opponentIndex] = opponent
		end
	end

	--apply walkover input
	match.walkover = string.upper(match.walkover or '')
	if Logic.isNumeric(match.walkover) then
		local winnerIndex = tonumber(match.walkover)
		opponents = matchFunctions._makeAllOpponentsLoseByWalkover(opponents, STATUS_DEFAULT_LOSS)
		opponents[winnerIndex].status = STATUS_DEFAULT_WIN
		match.finished = true
	elseif Logic.isNumeric(match.winner) and Table.includes(_ALLOWED_STATUSES, match.walkover) then
		local winnerIndex = tonumber(match.winner)
		opponents = matchFunctions._makeAllOpponentsLoseByWalkover(opponents, match.walkover)
		opponents[winnerIndex].status = STATUS_DEFAULT_WIN
		match.finished = true
	end

	-- see if match should actually be finished if score is set
	if not Logic.readBool(match.finished) then
		matchFunctions._finishMatch(match, opponents, isScoreSet)
	end

	-- apply placements and winner if finshed
	if Logic.readBool(match.finished) then
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

function matchFunctions._finishMatch(match, opponents, isScoreSet)
	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		match.finished = true
	end

	-- If special status has been applied to a team
	if CustomMatchGroupInput.placementCheckSpecialStatus(opponents) then
		match.finished = true
	end

	-- see if match should actually be finished if bestof limit was reached
	match.finished = Logic.readBool(match.finished)
		or isScoreSet and (
			Array.any(opponents, function(opponent) return (tonumber(opponent.score) or 0) > match.bestof/2 end)
			or Array.all(opponents, function(opponent) return (tonumber(opponent.score) or 0) == match.bestof/2 end)
		)

	-- If enough time has passed since match started, it should be marked as finished
	if isScoreSet and match.timestamp ~= DateExt.defaultTimestamp then
		local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT
			or SECONDS_UNTIL_FINISHED_NOT_EXACT
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	return match
end

function matchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for index in pairs(opponents) do
		opponents[index].score = NOT_PLAYED_SCORE
		opponents[index].status = walkoverType
	end
	return opponents
end

--
-- map related functions
--

-- Parse extradata information
function mapFunctions.getAdditionalExtraData(map)
	map.extradata.comment = map.comment
	map.extradata.team1side = string.lower(map.team1side or '')
	map.extradata.team2side = string.lower(map.team2side or '')

	return map
end

-- Parse participant information
function mapFunctions.getParticipants(map, opponents)
	local participants = {}
	local heroData = {}
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local hero = map['t' .. opponentIndex .. 'g' .. playerIndex]
			heroData['team' .. opponentIndex .. 'hero' .. playerIndex] = HeroNames[hero]
		end

		local banIndex = 1
		local nextBan = map['t' .. opponentIndex .. 'b' .. banIndex]
		while nextBan do
			heroData['team' .. opponentIndex .. 'ban' .. banIndex] = HeroNames[nextBan]
			banIndex = banIndex + 1
			nextBan = map['t' .. opponentIndex .. 'b' .. banIndex]
		end
	end

	map.extradata = heroData
	map.participants = participants
	return mapFunctions.getAdditionalExtraData(map)
end

-- Calculate Score and Winner of the map
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex] or map['t' .. scoreIndex .. 'score']
		local obj = {}
		if not Logic.isEmpty(score) then
			if Logic.isNumeric(score) then
				obj.status = STATUS_SCORE
				score = tonumber(score)
				map['score' .. scoreIndex] = score
				obj.score = score
			elseif Table.includes(_ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = NOT_PLAYED_SCORE
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end

	map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)

	return map
end

return CustomMatchGroupInput
