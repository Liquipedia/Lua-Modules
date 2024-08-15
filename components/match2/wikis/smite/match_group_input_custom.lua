---
-- @Liquipedia
-- wiki=smite
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local GodNames = mw.loadData('Module:GodNames')
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
local ALLOWED_STATUSES = {
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
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400
local DUMMY_MAP = 'default'

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
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	if map.map == DUMMY_MAP then
		map.map = nil
	end
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getPicksAndBans(map)
	map = mapFunctions.getAdditionalExtraData(map)

	return map
end

---@param record table
---@param timestamp number
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

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
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
		if MatchGroupInput.isDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, STATUS_DRAW)
		elseif MatchGroupInput.hasSpecialStatus(indexedScores) then
			data.winner = MatchGroupInput.hasDefaultWinner(indexedScores)
			data.resulttype = DEFAULT_RESULT_TYPE
			if MatchGroupInput.hasForfeit(indexedScores) then
				data.walkover = 'ff'
			elseif MatchGroupInput.hasDisqualified(indexedScores) then
				data.walkover = 'dq'
			elseif MatchGroupInput.hasDefaultWinLoss(indexedScores) then
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
	if Logic.isNotEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

---@param opponents table[]
---@param winner nil
---@param specialType nil
---@param finished nil
---@return table[], nil
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

--- @param tbl table
--- @param key1 string
--- @param key2 string
--- @return boolean
function CustomMatchGroupInput.placementSortFunction(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score or NO_SCORE) or NO_SCORE
	local value2 = tonumber(tbl[key2].score or NO_SCORE) or NO_SCORE
	return value1 > value2
end

--
-- match related functions
--
---@param match table
---@return table
function matchFunctions.getBestOf(match)
	match.bestof = #Array.filter(Array.range(1, MAX_NUM_GAMES), function(idx) return match['map'.. idx] end)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update an opponents result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
---@param match table
---@return table
function matchFunctions.getScoreFromMapWinners(match)
	local newScores = {}
	local setScores = false

	-- If the match has started, we want to use the automatic calculations
	if match.dateexact then
		if match.timestamp <= NOW then
			setScores = true
		end
	end

	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		local winner = tonumber(map.winner)
		if winner and winner > 0 and winner <= MAX_NUM_OPPONENTS then
			setScores = true
			newScores[winner] = (newScores[winner] or 0) + 1
		end
	end

	for index = 1, MAX_NUM_OPPONENTS do
		if not match['opponent' .. index].score and setScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

---@param match table
---@return table
function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {
		stats = match.stats,
		smiteesports = match.smiteesports
			and ('https://www.smiteesports.com/matches/' .. match.smiteesports) or nil,
	}
	return match
end

---@param match table
---@return table
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
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
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
			elseif opponent.type ~= Opponent.solo and opponent.type ~= Opponent.literal then
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
	elseif Logic.isNumeric(match.winner) and Table.includes(ALLOWED_STATUSES, match.walkover) then
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

---@param match table
---@param opponents table
---@param isScoreSet boolean
---@return table
function matchFunctions._finishMatch(match, opponents, isScoreSet)
	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		match.finished = true
	end

	-- If special status has been applied to a team
	if MatchGroupInput.hasSpecialStatus(opponents) then
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

---@param opponents table
---@param walkoverType string
---@return table
function matchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for index in pairs(opponents) do
		opponents[index].score = NOT_PLAYED_SCORE
		opponents[index].status = walkoverType
	end
	return opponents
end

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
	}
	return match
end

--
-- map related functions
--

-- Parse extradata information
---@param map table
---@return table
function mapFunctions.getAdditionalExtraData(map)
	map.extradata.comment = map.comment
	map.extradata.team1side = string.lower(map.team1side or '')
	map.extradata.team2side = string.lower(map.team2side or '')

	return map
end

---@param map table
---@return table
function mapFunctions.getPicksAndBans(map)
	local godData = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, GodNames)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local god = map['t' .. opponentIndex .. 'g' .. playerIndex]
			godData['team' .. opponentIndex .. 'god' .. playerIndex] = getCharacterName(god)

			local ban = map['t' .. opponentIndex .. 'b' .. playerIndex]
			godData['team' .. opponentIndex .. 'ban' .. playerIndex] = getCharacterName(ban)
		end
	end
	map.extradata = godData
	return map
end

-- Calculate Score and Winner of the map
---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	if Logic.isNumeric(map.winner) then
		map.winner = tonumber(map.winner)
		map.finished = true
	end

	return map
end

return CustomMatchGroupInput
