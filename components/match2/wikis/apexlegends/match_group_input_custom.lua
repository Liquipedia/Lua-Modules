---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

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
local MAX_NUM_OPPONENTS = 60
local MAX_NUM_PLAYERS = 3
local DEFAULT_MODE = 'team'
local NO_SCORE = -99
local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local NOT_PLAYED_SCORE = -1
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400
local EPOCH_TIME = '1970-01-01T00:00:00+00:00'
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}
local OpponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
	match = MatchFunctions.parseSetting(match)
	-- Adjust map data, especially set participants data
	match = MatchFunctions.adjustMapData(match)
	match = MatchFunctions.getScoreFromMaps(match)

	-- process match
	Table.mergeInto(match, MatchFunctions.readDate(match))
	match = MatchFunctions.getOpponents(match)
	match = MatchFunctions.getTournamentVars(match)
	match = MatchFunctions.getVodStuff(match)
	match = MatchFunctions.getExtraData(match)

	return match
end

function MatchFunctions.adjustMapData(match)
	local opponents = Array.mapIndexes(function(idx) return match['opponent' .. idx] end)
	local mapIndex = 1
	while match['map' .. mapIndex] do
		local map = match['map' .. mapIndex]
		local scores
		Table.mergeInto(map, MatchFunctions.readDate(map))
		map = MapFunctions.getParticipants(map, opponents)
		map = MapFunctions.getOpponentStats(map, opponents, mapIndex)
		map, scores = MapFunctions.getScoresAndWinner(map, match.scoreSettings)
		map = MapFunctions.getTournamentVars(map)
		map = MapFunctions.getExtraData(map, scores)

		match['map' .. mapIndex] = map
		mapIndex = mapIndex + 1
	end

	return match
end

-- called from Module:Match/Subobjects
CustomMatchGroupInput.processMap = FnUtil.identity

-- called from Module:Match/Subobjects
CustomMatchGroupInput.processPlayer = FnUtil.identity

--
--
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	local teamTemplateDate = timestamp
	-- If date is epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == DateExt.epochZero then
		teamTemplateDate = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	if Table.includes(NP_STATUSES, data.finished) then
		-- Map or Match wasn't played, set not played
		data.resulttype = 'np'
		data.finished = true
	elseif Logic.readBool(data.finished) then
		-- Map or Match is marked as finished.
		-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
		local winner
		indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, data.finished)
		data.winner = data.winner or winner
	end

	--set it as finished if we have a winner
	if not Logic.isEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

function CustomMatchGroupInput.setPlacement(opponents, winner, finished)
	local lastScore = NO_SCORE
	local lastPlacement = NO_SCORE
	local counter = 0
	for scoreIndex, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.placementSortFunction) do
		local score = tonumber(opp.score)
		counter = counter + 1
		if counter == 1 and String.isEmpty(winner) and finished then
			winner = scoreIndex
		end
		if lastScore == score then
			opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or lastPlacement
		else
			opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or counter
			lastPlacement = counter
			lastScore = score or NO_SCORE
		end
	end

	return opponents, winner
end

function CustomMatchGroupInput.placementSortFunction(table, key1, key2)
	local value1 = tonumber(table[key1].score) or NO_SCORE
	local value2 = tonumber(table[key2].score) or NO_SCORE
	return value1 > value2
end

--
-- match related functions
--
function MatchFunctions.parseSetting(match)
	-- Score Settings
	match.scoreSettings = {
		kill = tonumber(match.p_kill) or 1,
	}

	Table.mergeInto(match.scoreSettings, Array.mapIndexes(function(idx)
		return tonumber(match['p' .. idx])
	end))

	-- Up/Down colors and 
	match.statusSettings = {
		advTitle = match.advtitle,
		outTitle = match.outtitle,
		advCount = match.advteams,
		advColor = match.advcolor,
		outColor = match.outcolor,
	}

	return match
end

-- Calculate the points based on the map results
function MatchFunctions.getScoreFromMaps(match)
	local newScores = {}

	local mapIndex = 1
	while match['map' .. mapIndex] do
		for index = 1, MAX_NUM_OPPONENTS do
			newScores[index] = (newScores[index] or 0) + (match['map' .. mapIndex].scores[index] or 0)
		end
		mapIndex = mapIndex + 1
	end

	for index = 1, MAX_NUM_OPPONENTS do
		if match['opponent' .. index] and not match['opponent' .. index].score then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

function MatchFunctions.readDate(matchArgs)
	if matchArgs.date then
		return MatchGroupInput.readDate(matchArgs.date)
	else
		return {
			date = EPOCH_TIME,
			dateexact = false,
			timestamp = DateExt.epochZero,
		}
	end
end

function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function MatchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {
		stats = match.stats,
	}

	return match
end

function MatchFunctions.getExtraData(match)
	match.extradata = {
		scoring = match.scoreSettings,
		status = match.statusSettings,
	}

	return match
end

function MatchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = OpponentFunctions.getIcon(opponent.template)
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
					match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
						resolveRedirect = true,
						applyUnderScores = true,
						maxNumPlayers = MAX_NUM_PLAYERS,
					})
				end
			elseif Opponent.typeIsParty(opponent) then
				opponent.match2players = Json.parseIfString(opponent.match2players) or {}
				opponent.match2players[1].name = opponent.name
			elseif opponent.type ~= Opponent.literal then
				error('Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
			end

			opponents[opponentIndex] = opponent
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.epochZero then
		local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT or SECONDS_UNTIL_FINISHED_NOT_EXACT
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if not Logic.isEmpty(match.winner) or Logic.readBool(match.finished) then
		match.finished = true
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

--
-- map related functions
--

-- Parse extradata information
function MapFunctions.getExtraData(map, scores)
	map.extradata = {
		comment = map.comment,
		opponents = scores,
	}

	return map
end

-- Parse participant information
function MapFunctions.getParticipants(map, opponents)
	local participants = {}
	for opponentIndex, opponent in ipairs(opponents) do
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local player = Json.parseIfString(opponent['p'.. playerIndex])
			if player then
				participants = MapFunctions.attachToParticipant(
					player,
					opponentIndex,
					opponent.match2players,
					participants
				)
			end
		end
	end

	map.participants = participants
	return map
end

function MapFunctions.attachToParticipant(player, opponentIndex, players, participants)
	player.player = mw.ext.TeamLiquidIntegration.resolve_redirect(player):gsub(' ', '_')
	for playerIndex, item in pairs(players or {}) do
		if player.player == item.name then
			participants[opponentIndex .. '_' .. playerIndex] = player
			break
		end
	end

	return participants
end

function MapFunctions.getOpponentStats(map, opponents, idx)
	for oppIdx, opponent in pairs(opponents) do
		map['t'.. oppIdx ..'data'] = Json.parseIfString(opponent['m' .. idx])
	end

	return map
end

-- Calculate Score and Winner of the map
function MapFunctions.getScoresAndWinner(map, scoreSettings)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local teamData = map['t' .. scoreIndex .. 'data']
		if not teamData then
			break
		end
		local score = NO_SCORE
		local scoreBreakdown = {}
		if Logic.isNumeric(teamData[1]) and Logic.isNumeric(teamData[2]) then
			scoreBreakdown.placePoints = (scoreSettings[tonumber(teamData[1])] or 0)
			scoreBreakdown.killPoints = tonumber(teamData[2]) * scoreSettings.kill
			score = scoreBreakdown.placePoints + scoreBreakdown.killPoints
		end
		local opponent = {
			status = STATUS_SCORE,
			score = score,
			scoreBreakdown = scoreBreakdown,
		}
		table.insert(map.scores, score)
		indexedScores[scoreIndex] = opponent
	end

	map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)

	return map, indexedScores
end

function MapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	return MatchGroupInput.getCommonTournamentVars(map)
end

--
-- opponent related functions
--
function OpponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

return CustomMatchGroupInput
