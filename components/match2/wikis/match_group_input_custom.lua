---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local WeaponNames = mw.loadData('Module:WeaponNames')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

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
local ALLOWED_VETOES = {'decider', 'pick', 'ban', 'defaultban'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 15
local MAX_NUM_GAMES = 7
local DEFAULT_MODE = 'team'
local DEFAULT_GAME = ''
local NO_SCORE = -99
local DUMMY_MAP = 'default'
local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'
local DEFAULT_RESULT_TYPE = 'default'
local NOT_PLAYED_SCORE = -1
local NO_WINNER = -1

local CURRENT_TIME_UNIX = os.time(os.date('!*t'))

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(_, match)
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
	match = matchFunctions.getLinks(match)
	match = matchFunctions.getExtraData(match)

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
function CustomMatchGroupInput.processMap(_, map)
	if map.map == DUMMY_MAP then
		map.map = nil
	end
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	local teamTemplateDate = timestamp
	-- If date if epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == DateExt.epochZero then
		teamTemplateDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			EPOCH_TIME_EXTENDED
		)
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(_, player)
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
	elseif specialType == DEFAULT_RESULT_TYPE then
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
			local score = tonumber(opp.score) or ''
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
	if Logic.isNumeric(match.bestof) then
		match.bestof = tonumber(match.bestof)
	else
		local mapCount = 0
		for i = 1, MAX_NUM_GAMES do
			if match['map'..i] then
				mapCount = mapCount + 1
			else
				break
			end
		end
		match.bestof = mapCount
	end

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
		if matchUnixTime <= CURRENT_TIME_UNIX then
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

function matchFunctions.readDate(matchArgs)
	if matchArgs.date then
		local dateProps = MatchGroupInput.readDate(matchArgs.date)
		dateProps.hasDate = true
		return dateProps
	else
		return {
			date = EPOCH_TIME_EXTENDED,
			dateexact = false,
			timestamp = DateExt.epochZero,
		}
	end
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game', DEFAULT_GAME))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)

	for index = 1, MAX_NUM_GAMES do
		local vodgame = match['vodgame' .. index]
		if not Logic.isEmpty(vodgame) then
			local map = match['map' .. index] or {}
			map.vod = map.vod or vodgame
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

	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = matchFunctions.getMapVeto(match),
		mvp = MatchGroupInput.readMvp(match),
	}

	return match
end

-- Parse the mapVeto input
function matchFunctions.getMapVeto(match)
	if not match.mapveto then return nil end

	match.mapveto = Json.parseIfString(match.mapveto)

	local vetotypes = mw.text.split(match.mapveto.types or '', ',')
	local deciders = mw.text.split(match.mapveto.decider or '', ',')
	local vetostart = match.mapveto.firstpick or ''
	local deciderIndex = 1

	local data = {}
	for index, vetoType in ipairs(vetotypes) do
		vetoType = mw.text.trim(vetoType):lower()
		if not Table.includes(ALLOWED_VETOES, vetoType) then
			return nil -- Any invalid input will not store (ie hide) all vetoes.
		elseif vetoType == 'decider' then
			table.insert(data, {type = vetoType, decider = deciders[deciderIndex]})
			deciderIndex = deciderIndex + 1
		else
			table.insert(data, {type = vetoType, team1 = match.mapveto['t1map'..index], team2 = match.mapveto['t2map'..index]})
		end
	end

	if data[1] then
		data[1].vetostart = vetostart
	end

	return data
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

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getIcon(opponent.template)
			end

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
					match = matchFunctions.getPlayersOfTeam(match, opponentIndex, opponent.name)
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

function matchFunctions._finishMatch(match, opponents, isScoreSet)
	-- If a winner has been set
	if String.isNotEmpty(match.winner) then
		match.finished = true
	end

	-- If special status has been applied to a team
	if CustomMatchGroupInput.placementCheckSpecialStatus(opponents) then
		match.finished = true
	end

	-- Check if all/enough games have been played. If they have, mark as finished
	if isScoreSet then
		local firstTo = math.floor(match.bestof / 2)
		local scoreSum = 0
		for _, item in pairs(opponents) do
			local score = tonumber(item.score or 0)
			if score > firstTo then
				match.finished = true
				break
			end
			scoreSum = scoreSum + score
		end
		if scoreSum >= match.bestof then
			match.finished = true
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.epochZero then
		local currentUnixTime = os.time(os.date('!*t'))
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < currentUnixTime then
			match.finished = true
		end
	end

	return match
end

function matchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for index, _ in pairs(opponents) do
		opponents[index].score = NOT_PLAYED_SCORE
		opponents[index].status = walkoverType
	end
	return opponents
end

-- Get Playerdata from Vars (get's set in TeamCards)
function matchFunctions.getPlayersOfTeam(match, oppIndex, teamName)
	-- match._storePlayers will break after the first empty player. let's make sure we don't leave any gaps.
	local players = {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		local player = Json.parseIfString(match['opponent' .. oppIndex .. '_p' .. playerIndex]) or {}
		player.name = player.name or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		player.displayname = player.displayname or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'dn')

		if String.isNotEmpty(player.name) then
			player.name = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name):gsub(' ', '_')
		end

		if not Table.isEmpty(player) then
			table.insert(players, player)
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
	map.extradata = Table.merge(map.extradata, {
		comment = map.comment,
		header = map.header,
		maptype = map.maptype,
	})

	return map
end

-- Parse participant information
function mapFunctions.getParticipants(map, opponents)
	local participants = {}
	local maximumPickIndex = 0
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for _, player, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
			participants[opponentIndex .. '_' .. playerIndex] = {player = player}
		end

		for _, weapon, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'w') do
			local participantsKey = opponentIndex .. '_' .. pickIndex
			participants[participantsKey] = Table.merge(participants[participantsKey]
				or {}, {weapon = mapFunctions._cleanWeaponName(weapon)})
			if maximumPickIndex < pickIndex then
				maximumPickIndex = pickIndex
			end
		end
	end

	map.extradata = {maximumpickindex = maximumPickIndex}
	map.participants = participants

	return mapFunctions.getAdditionalExtraData(map)
end

function mapFunctions._cleanWeaponName(weaponRaw)
	local weapon = WeaponNames[string.lower(weaponRaw)]
	if not weapon then
		error('Unsupported weapon input: ' .. weaponRaw)
	end

	return weapon
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
			elseif Table.includes(ALLOWED_STATUSES, score) then
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

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	map.game = Logic.emptyOr(map.game, Variables.varDefault('tournament_game', DEFAULT_GAME))
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
