---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local HeroNames = mw.loadData('Module:HeroNames')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

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
local _MAX_NUM_PLAYERS = 15
local _MAX_NUM_GAMES = 7
local _DEFAULT_BESTOF = 3
local _DEFAULT_MODE = 'team'
local _DEFAULT_GAME = 'dota2'
local _NO_SCORE = -99
local _DUMMY_MAP = 'default'
local _NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'
local _DEFAULT_RESULT_TYPE = 'default'
local _NOT_PLAYED_SCORE = -1
local _NO_WINNER = -1
local _SECONDS_UNTIL_FINISHED_EXACT = 30800
local _SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400
local _MIN_EARNINGS_FOR_FEATURED = 100000

local _CURRENT_TIME_UNIX = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
	-- process match
	Table.mergeInto(
		match,
		matchFunctions.readDate(match)
	)
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getScoreFromMapWinners(match)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getPublisherId(match)
	match = matchFunctions.getLinks(match)
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
function CustomMatchGroupInput.processMap(map)
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

	local teamTemplateDate = date
	-- If date if epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == _EPOCH_TIME_EXTENDED then
		teamTemplateDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			_EPOCH_TIME_EXTENDED
		)
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
-- function to check for draws
--
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

	-- set it as finished if we have a winner
	if not Logic.isEmpty(data.winner) then
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
			local score = tonumber(opp.score)
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
				lastScore = score or _NO_SCORE
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
	return Table.any(table,
		function (_, scoreinfo)
			return scoreinfo.status ~= _STATUS_SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
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
	local setScores = false

	-- If the match has started, we want to use the automatic calculations
	if match.dateexact then
		local matchUnixTime = tonumber(mw.getContentLanguage():formatDate('U', match.date))
		if matchUnixTime <= _CURRENT_TIME_UNIX then
			setScores = true
		end
	end

	local mapIndex = 1
	while match['map'..mapIndex] do
		local winner = tonumber(match['map'..mapIndex].winner)
		if winner and winner > 0 and winner <= _MAX_NUM_OPPONENTS then
			setScores = true
			newScores[winner] = (newScores[winner] or 0) + 1
		end
		mapIndex = mapIndex + 1
	end

	for index = 1, _MAX_NUM_OPPONENTS do
		if not match['opponent' .. index].score and setScores then
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
			date = _EPOCH_TIME_EXTENDED,
			dateexact = false,
		}
	end
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', _DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))

	-- needed due to _DEFAULT_GAME
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game', _DEFAULT_GAME))

	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)

	for index = 1, _MAX_NUM_GAMES do
		local vodgame = match['vodgame' .. index]
		if not Logic.isEmpty(vodgame) then
			local map = match['map' .. index] or {}
			map.vod = map.vod or vodgame
			match['map' .. index] = map
		end
	end

	return match
end

function matchFunctions.getPublisherId(match)
	for index = 1, _MAX_NUM_GAMES do
		local publisherid = match['matchid' .. index]
		if not Logic.isEmpty(publisherid) then
			local map = match['map' .. index] or {}
			map.publisherid = map.matchid or publisherid
			match['map' .. index] = map
		end
	end

	return match
end

function matchFunctions.getLinks(match)
	match.links = {
		preview = match.preview,
		lrthread = match.lrthread,
		interview = match.interview,
		review = match.review,
		recap = match.recap,
	}
	if match.faceit then match.links.faceit = 'https://www.faceit.com/en/dota2/room/' .. match.faceit end
	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		featured = Logic.emptyOr(
			match.featured,
			matchFunctions.isFeatured(match)
		),
		mvp = MatchGroupInput.readMvp(match),
		headtohead = match.headtohead,
	}
	return match
end

function matchFunctions.isFeatured(match)
	local tier = tonumber(match.liquipediatier or '')
	if tier == 1 or tier == 2 then
		return true
	end

	local opponent1, opponent2 = match.opponent1, match.opponent2
	local year, month = match.date:match('^(%d%d%d%d)-(%d%d)')
	if year == '1970' then
		return false
	end
	if tonumber(month) < 3 then
		year = tonumber(year) - 1
	end

	if
		opponent1.type == Opponent.team and
		matchFunctions.getEarnings(opponent1.name, year) >= _MIN_EARNINGS_FOR_FEATURED
	or
		opponent2.type == Opponent.team and
		matchFunctions.getEarnings(opponent2.name, year) >= _MIN_EARNINGS_FOR_FEATURED
	then
		return true
	end

	return false
end

function matchFunctions.getEarnings(name, year)
	if String.isEmpty(name) then
		return 0
	end

	if String.isNotEmpty(Variables.varDefault(name .. '_featured_earnings')) then
		return tonumber(Variables.varDefault(name .. '_featured_earnings'))
	end

	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[pagename::' .. name:gsub(' ', '_') .. ']]',
		query = 'extradata'
	})

	local currentEarnings = 0
	if type(data[1]) == 'table' then
		currentEarnings = tonumber((data[1].extradata or {})['earningsin' .. year] or 0) or 0
	end

	Variables.varDefine(name .. '_featured_earnings', currentEarnings)

	return currentEarnings
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
				opponent.icon, opponent.icondark = opponentFunctions.getIcon(opponent.template)
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
			if opponent.type == Opponent.team then
				if not Logic.isEmpty(opponent.name) then
					match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
						resolveRedirect = true,
						applyUnderScores = true,
						maxNumPlayers = _MAX_NUM_PLAYERS,
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
		local firstTo = math.floor(match.bestof / 2)
		for _, item in pairs(opponents) do
			if tonumber(item.score or 0) > firstTo then
				match.finished = true
				break
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.hasDate then
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', match.date))
		local threshold = match.dateexact and _SECONDS_UNTIL_FINISHED_EXACT
			or _SECONDS_UNTIL_FINISHED_NOT_EXACT
		if matchUnixTime + threshold < _CURRENT_TIME_UNIX then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if
		not Logic.isEmpty(match.winner) or
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
	map.extradata.publisherid = map.publisherid or ''

	return map
end

-- Parse participant information
function mapFunctions.getParticipants(map, opponents)
	local participants = {}
	local heroData = {}
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
		for playerIndex = 1, _MAX_NUM_PLAYERS do
			local hero = map['t' .. opponentIndex .. 'h' .. playerIndex]
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
	map.game = Logic.emptyOr(map.game, Variables.varDefault('tournament_game', _DEFAULT_GAME))
	return MatchGroupInput.getCommonTournamentVars(map)
end

--
-- opponent related functions
--
function opponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

return CustomMatchGroupInput
