---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ChampionNames = mw.loadData('Module:ChampionNames')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local _STATUS_SCORE = 'S'
local _STATUS_DRAW = 'D'
local _STATUS_DEFAULT_WIN = 'W'
local _STATUS_FORFEIT = 'FF'
local _STATUS_DISQUALIFIED = 'DQ'
local _STATUS_DEFAULT_LOSS = 'L'
local _ALLOWED_STATUSES = {
	_STATUS_DRAW,
	_STATUS_DEFAULT_WIN,
	_STATUS_FORFEIT,
	_STATUS_DISQUALIFIED,
	_STATUS_DEFAULT_LOSS,
}
local _MAX_NUM_OPPONENTS = 2
local _MAX_NUM_PLAYERS = 5
local _DEFAULT_BESTOF = 3
local _DEFAULT_MODE = 'team'
local _NO_SCORE = -99
local _DUMMY_MAP = 'default'
local _NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local _EPOCH_TIME = '1970-01-01 00:00:00'
local _DEFAULT_RESULT_TYPE = 'default'
local _TEAM_OPPONENT_TYPE = 'team'
local _NOT_PLAYED_SCORE = -1
local _NO_WINNER = -1
local _SECONDS_UNTIL_FINISHED_EXACT = 30800
local _SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(_, match)
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

	-- Adjust map data, especially set participants data
	match = matchFunctions.adjustMapData(match)

	return match
end

function matchFunctions.adjustMapData(match)
	local opponents = {}
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
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
function CustomMatchGroupInput.processMap(_, map)
	if map.map == _DUMMY_MAP then
		map.map = nil
	end
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	Opponent.resolve(opponent, date)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(_, player)
	return player
end

--
--
-- function to check for draws
function CustomMatchGroupInput.placementCheckDraw(table)
	local last
	for _, scoreInfo in pairs(table) do
		if scoreInfo.status ~= _STATUS_SCORE and scoreInfo.status ~= _STATUS_DRAW then
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
		Table.includes(_NP_STATUSES, data.finished) or
		Table.includes(_NP_STATUSES, data.winner)
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
			data.resulttype = _DEFAULT_RESULT_TYPE
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, _DEFAULT_RESULT_TYPE)
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
	elseif specialType == _DEFAULT_RESULT_TYPE then
		for key, _ in pairs(opponents) do
			if key == winner then
				opponents[key].placement = 1
			else
				opponents[key].placement = 2
			end
		end
	else
		local lastScore = _NO_SCORE
		local lastPlacement = _NO_SCORE
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
	local value1 = tonumber(table[key1].score or _NO_SCORE) or _NO_SCORE
	local value2 = tonumber(table[key2].score or _NO_SCORE) or _NO_SCORE
	return value1 > value2
end

-- Check if any opponent has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status ~= _STATUS_SCORE end)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == _STATUS_FORFEIT end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == _STATUS_DISQUALIFIED end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == _STATUS_DEFAULT_LOSS end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(table)
	for index, scoreInfo in pairs(table) do
		if scoreInfo.status == _STATUS_DEFAULT_WIN then
			return index
		end
	end
	return _NO_WINNER
end

--
-- match related functions
--
function matchFunctions.getBestOf(match)
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof', _DEFAULT_BESTOF))
	Variables.varDefine('bestof', match.bestof)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update an opponents result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	local newScores = {}
	local foundScores = false

	local mapIndex = 1
	while match['map'..mapIndex] do
		local winner = tonumber(match['map'..mapIndex].winner)
		foundScores = true
		if winner and winner > 0 and winner <= _MAX_NUM_OPPONENTS then
			newScores[winner] = (newScores[winner] or 0) + 1
		end
		mapIndex = mapIndex + 1
	end

	for index = 1, _MAX_NUM_OPPONENTS do
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
		local suggestedDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			_EPOCH_TIME
		)
		return {
			date = MatchGroupInput.getInexactDate(suggestedDate),
			dateexact = false,
		}
	end
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', _DEFAULT_MODE))
	match.type = Logic.emptyOr(match.type, Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_tickername'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
	match.icondark = Logic.emptyOr(match.iconDark, Variables.varDefault("tournament_icondark"))
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault('tournament_liquipediatier'))
	match.liquipediatiertype = Logic.emptyOr(
		match.liquipediatiertype,
		Variables.varDefault('tournament_liquipediatiertype')
	)
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return match
end

function matchFunctions.getVodStuff(match)
	match.stream = match.stream or {}
	match.stream = {
		stream = Logic.emptyOr(match.stream.stream, Variables.varDefault('stream')),
		twitch = Logic.emptyOr(match.stream.twitch or match.twitch, Variables.varDefault('twitch')),
		twitch2 = Logic.emptyOr(match.stream.twitch2 or match.twitch2, Variables.varDefault('twitch2')),
		nimo = Logic.emptyOr(match.stream.nimo or match.nimo, Variables.varDefault('nimo')),
		trovo = Logic.emptyOr(match.stream.trovo or match.trovo, Variables.varDefault('trovo')),
		huya = Logic.emptyOr(match.stream.huya or match.huya, Variables.varDefault('huya')),
		afreeca = Logic.emptyOr(match.stream.afreeca or match.afreeca, Variables.varDefault('afreeca')),
		afreecatv = Logic.emptyOr(match.stream.afreecatv or match.afreecatv, Variables.varDefault('afreecatv')),
		dailymotion = Logic.emptyOr(match.stream.dailymotion or match.dailymotion, Variables.varDefault('dailymotion')),
		douyu = Logic.emptyOr(match.stream.douyu or match.douyu, Variables.varDefault('douyu')),
		smashcast = Logic.emptyOr(match.stream.smashcast or match.smashcast, Variables.varDefault('smashcast')),
		youtube = Logic.emptyOr(match.stream.youtube or match.youtube, Variables.varDefault('youtube')),
		facebook = Logic.emptyOr(match.stream.facebook or match.facebook, Variables.varDefault('facebook')),
	}
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {}
	local links = match.links
	if match.reddit then links.reddit = match.reddit end

	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		matchsection = Variables.varDefault('matchsection'),
		comment = match.comment,
		mvp = match.mvp,
		mvpteam = match.mvpteam or match.winner
	}
	return match
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.date)

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon = opponentFunctions.getIcon(opponent.template)
			end

			-- apply status
			opponent.score = string.upper(opponent.score or '')
			if Logic.isNumeric(opponent.score) then
				opponent.score = tonumber(opponent.score)
				opponent.status = _STATUS_SCORE
				isScoreSet = true
			elseif Table.includes(_ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = _NOT_PLAYED_SCORE
			end

			-- get players from vars for teams
			if opponent.type == _TEAM_OPPONENT_TYPE then
				if not Logic.isEmpty(opponent.name) then
					match = matchFunctions.getPlayersOfTeam(match, opponentIndex, opponent.name, opponent.players)
				end
			elseif opponent.type == 'solo' then
				opponent.match2players = Json.parseIfString(opponent.match2players) or {}
				opponent.match2players[1].name = opponent.name
			else
				error('Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
			end

			opponents[opponentIndex] = opponent
		end
	end

	--apply walkover input
	match.walkover = string.upper(match.walkover or '')
	if Logic.isNumeric(match.walkover) then
		local winnerIndex = tonumber(match.walkover)
		opponents = matchFunctions._makeAllOpponentsLoseByWalkover(opponents, _STATUS_DEFAULT_LOSS)
		opponents[winnerIndex].status = _STATUS_DEFAULT_WIN
		match.finished = true
	elseif Logic.isNumeric(match.winner) and Table.includes(_ALLOWED_STATUSES, match.walkover) then
		local winnerIndex = tonumber(match.winner)
		opponents = matchFunctions._makeAllOpponentsLoseByWalkover(opponents, match.walkover)
		opponents[winnerIndex].status = _STATUS_DEFAULT_WIN
		match.finished = true
	end

	-- see if match should actually be finished if bestof limit was reached
	if isScoreSet and not Logic.readBool(match.finished) then
		local firstTo = math.ceil(match.bestof/2)
		for _, item in pairs(opponents) do
			if tonumber(item.score or 0) >= firstTo then
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
		local threshold = match.dateexact and _SECONDS_UNTIL_FINISHED_EXACT
			or _SECONDS_UNTIL_FINISHED_NOT_EXACT
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if
		not String.isEmpty(match.winner) or
		Logic.readBool(match.finished) or
		CustomMatchGroupInput.placementCheckSpecialStatus(opponents)
	then
		match.finished = true
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

function matchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for index, _ in pairs(opponents) do
		opponents[index].score = _NOT_PLAYED_SCORE
		opponents[index].status = walkoverType
	end
end

-- Get Playerdata from Vars (get's set in TeamCards)
function matchFunctions.getPlayersOfTeam(match, oppIndex, teamName, playersData)
	-- match._storePlayers will break after the first empty player. let's make sure we don't leave any gaps.
	playersData = Json.parseIfString(playersData) or {}
	local players = {}
	local count = 1
	for playerIndex = 1, _MAX_NUM_PLAYERS do
		-- parse player
		local player = Json.parseIfString(match['opponent' .. oppIndex .. '_p' .. playerIndex]) or {}
		player.name = player.name or playersData['p' .. playerIndex]
			or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or playersData['p' .. playerIndex .. 'flag']
			or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		player.displayname = player.displayname or playersData['p' .. playerIndex .. 'dn']
			or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'dn')

		if String.isNotEmpty(player.name) then
			player.name = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name)
		end

		if not Table.isEmpty(player) then
			table.insert(players, player)
			count = count + 1
		end
	end
	match['opponent' .. oppIndex].match2players = players
	return match
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
	local championData = {}
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
		for playerIndex = 1, _MAX_NUM_PLAYERS do
			local champ = map['t' .. opponentIndex .. 'c' .. playerIndex]
			championData['team' .. opponentIndex .. 'champion' .. playerIndex] =
				ChampionNames[champ] or champ

			championData['t' .. opponentIndex .. 'kda' .. playerIndex] =
				map['t' .. opponentIndex .. 'kda' .. playerIndex]

			local player = map['t' .. opponentIndex .. 'p' .. playerIndex]
			if String.isNotEmpty(player) then
				participants = mapFunctions.attachToParticipant(
					player,
					opponentIndex,
					opponents[opponentIndex].match2players,
					participants,
					championData['team' .. opponentIndex .. 'champion' .. playerIndex],
					championData['team' .. opponentIndex .. 'kda' .. playerIndex]
				)
			end
		end
		local banIndex = 1
		local currentBan = map['t' .. opponentIndex .. 'b' .. banIndex]
		while currentBan do
			championData['team' .. opponentIndex .. 'ban' .. banIndex] = ChampionNames[currentBan] or currentBan
			banIndex = banIndex + 1
			currentBan = map['t' .. opponentIndex .. 'b' .. banIndex]
		end
	end

	map.extradata = championData
	map.participants = participants
	return mapFunctions.getAdditionalExtraData(map)
end

function mapFunctions.attachToParticipant(player, opponentIndex, players, participants, champion, kda)
	player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	for playerIndex, item in pairs(players or {}) do
		if player == item.name then
			participants[opponentIndex .. '_' .. playerIndex] = {
				champion = champion,
				kda = kda
			}
			break
		end
	end

	return participants
end

-- Calculate Score and Winner of the map
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, _MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex] or map['t' .. scoreIndex .. 'score']
		local obj = {}
		if not Logic.isEmpty(score) then
			if Logic.isNumeric(score) then
				obj.status = _STATUS_SCORE
				score = tonumber(score)
				map['score' .. scoreIndex] = score
				obj.score = score
			elseif Table.includes(_ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = _NOT_PLAYED_SCORE
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
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', _DEFAULT_MODE))
	map.type = Logic.emptyOr(map.type, Variables.varDefault('tournament_type'))
	map.tournament = Logic.emptyOr(map.tournament, Variables.varDefault('tournament_name'))
	map.shortname = Logic.emptyOr(map.shortname, Variables.varDefault('tournament_shortname'))
	map.series = Logic.emptyOr(map.series, Variables.varDefault('tournament_series'))
	map.icon = Logic.emptyOr(map.icon, Variables.varDefault('tournament_icon'))
	map.icondark = Logic.emptyOr(map.iconDark, Variables.varDefault("tournament_icondark"))
	map.liquipediatier = Logic.emptyOr(map.liquipediatier, Variables.varDefault('tournament_liquipediatier'))
	map.liquipediatiertype = Logic.emptyOr(map.liquipediatiertype, Variables.varDefault('tournament_liquipediatiertype'))
	return map
end

--
-- opponent related functions
--
function opponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	return raw and Logic.emptyOr(raw.image, raw.legacyimage)
end

return CustomMatchGroupInput
