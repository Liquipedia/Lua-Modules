---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L', 'D'}
local FINISHED_INDICATORS = {'skip', 'np', 'cancelled', 'canceled'}
local MAX_NUM_OPPONENTS = 8
local MAX_NUM_PLAYERS = 10
local MAX_NUM_MAPS = 9
local DEFAULT_BESTOF = 3
local NO_SCORE = -99
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400
local ALLOWED_OPPONENT_TYPES = {
	'solo',
	'team'
}

local EPOCH_TIME = '1970-01-01 00:00:00'

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(
		match,
		matchFunctions.readDate(match)
	)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date, opponentIndex)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Retrieve icon for teams and do tbd checks
	if opponent.type == Opponent.team then
		if opponent.template:lower() == 'bye' then
			opponent = {type = Opponent.literal, name = 'BYE'}
		else
			opponent.icon = opponentFunctions.getIcon(opponent.template)
		end
	elseif opponent.type ~= Opponent.literal then
		if not ALLOWED_OPPONENT_TYPES[opponent.type or ''] then
			error('Unsupported opponent type "' .. (opponent.type or '') .. '"')
		end
		opponent.match2players = matchFunctions.readSoloOpponent(record, opponentIndex)
		if Array.any(opponent.match2players, CustomMatchGroupInput._playerIsBye) then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

	end

	Opponent.resolve(opponent, date)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
--
-- function to check for draws
function CustomMatchGroupInput.placementCheckDraw(table)
	local last
	for _, scoreInfo in pairs(table) do
		if scoreInfo.status ~= 'S' and scoreInfo.status ~= 'D' then
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
	if Table.includes(FINISHED_INDICATORS, data.finished) or Table.includes(FINISHED_INDICATORS, data.winner) then
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
			data.resulttype = 'default'
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 'default')
		else
			local winner
			indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, nil, data.finished)
			data.winner = data.winner or winner
		end
	end

	--set it as finished if we have a winner
	if not String.isEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

function CustomMatchGroupInput.setPlacement(opponents, winner, specialType, finished)
	if specialType == 'draw' then
		for key, _ in pairs(opponents) do
			opponents[key].placement = 1
		end
	elseif specialType == 'default' then
		for key, _ in pairs(opponents) do
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
			local score = tonumber(opp.score or '') or ''
			counter = counter + 1
			if counter == 1 and (winner or '') == '' then
				if finished then
					winner = scoreIndex
				end
			end
			if lastScore == score then
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or lastPlacement
			else
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or counter
				lastPlacement = counter
				lastScore = score
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

-- Check if any team has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(table)
	for index, scoreInfo in pairs(table) do
		if scoreInfo.status == 'W' then
			return index
		end
	end
	return -1
end

--
-- match related functions
--
function matchFunctions.getBestOf(match)
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof', DEFAULT_BESTOF))
	Variables.varDefine('bestof', match.bestof)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	local opponentNumber = 0
	for index = 1, MAX_NUM_OPPONENTS do
		if String.isEmpty(match['opponent' .. index]) then
			break
		end
		opponentNumber = index
	end
	local newScores = {}
	local foundScores = false

	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			local winner = tonumber(match['map'..i].winner)
			foundScores = true
			if winner and winner > 0 and winner <= opponentNumber then
				newScores[winner] = (newScores[winner] or 0) + 1
			end
		else
			break
		end
	end

	for index = 1, opponentNumber do
		if not match['opponent' .. index].score and foundScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

function matchFunctions.readDate(matchArgs)
	if matchArgs.date then
		local dateProps = MatchGroupInput.readDate(matchArgs.date)
		dateProps.hasDate = true
		return dateProps
	else
		return {
			date = mw.getContentLanguage():formatDate('c', EPOCH_TIME),
			dateexact = false,
		}
	end
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {}
	local links = match.links
	if match.reddit then links.reddit = 'https://redd.it/' .. match.reddit end
	if match.cdl then links.cdl = 'https://callofdutyleague.com/en-us/match/' .. match.cdl end

	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		mvp = MatchGroupInput.readMvp(match),
		mvpteam = match.mvpteam or match.winner
	}

	return match
end

-- Parse MVP input
function matchFunctions.getMVP(match)
	if not match.mvp then return {} end
	local mvppoints = match.mvppoints or 1

	-- Split the input
	local players = mw.text.split(match.mvp, ',')

	-- Trim the input
	for index, player in pairs(players) do
		players[index] = mw.text.trim(player)
	end

	return {players = players, points = mvppoints}
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.date)

			-- apply status
			if Logic.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				match = matchFunctions.getTeamPlayers(match, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if bestof limit was reached
	if isScoreSet and not Logic.readBool(match.finished) then
		local firstTo = math.ceil(match.bestof / 2)
		for _, item in pairs(opponents) do
			if (tonumber(item.score or 0) or 0) >= firstTo then
				match.finished = true
				break
			end
		end
	end

	-- check if match should actually be finished due to a non score status
	if not Logic.readBool(match.finished) then
		for _, opponent in pairs(opponents) do
			if String.isNotEmpty(opponent.status) and opponent.status ~= 'S' then
				match.finished = true
				break
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.hasDate then
		local currentUnixTime = os.time(os.date('!*t'))
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', match.date))
		local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT
			or SECONDS_UNTIL_FINISHED_NOT_EXACT
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if not String.isEmpty(match.winner) or Logic.readBool(match.finished) then
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

-- Get Playerdata from Vars (get's set in TeamCards) for team opponents
function matchFunctions.getTeamPlayers(match, opponentIndex, teamName)
	-- let's make sure we don't leave any gaps.
	match['opponent' .. opponentIndex].match2players = {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		local player = Json.parseIfString(match['opponent' .. opponentIndex .. '_p' .. playerIndex]) or {}
		player.name = player.name or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		player.displayname = player.displayname or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'dn')
		if not Table.isEmpty(player) then
			table.insert(match['opponent' .. opponentIndex].match2players, player)
		end
	end

	return match
end

-- Get Playerdata for solo opponents
function matchFunctions.readSoloOpponent(match, opponentIndex)
	local player = Json.parseIfString(match['opponent' .. opponentIndex .. '_p1']) or {}
	player.name = player.name or 'TBD'
	player.flag = player.flag
	player.displayname = player.displayname or player.name
	return {player}
end

function CustomMatchGroupInput._playerIsBye(player)
	return (player.name or ''):lower() == 'bye' or (player.displayname or ''):lower() == 'bye'
end

--
-- map related functions
--

-- Parse extradata information
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
	}
	return map
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
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
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

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInput.getCommonTournamentVars(map)
end

--
-- opponent related functions
--
function opponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	return raw and Logic.emptyOr(raw.image, raw.legacyimage)
end

return CustomMatchGroupInput
