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
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
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
local MAX_NUM_OPPONENTS = 60
local MAX_NUM_PLAYERS = 3
local DEFAULT_MODE = 'team'
local NO_SCORE = -99
local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local NOT_PLAYED_SCORE = -1
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	match = MatchFunctions.parseSetting(match)
	-- Adjust map data, especially set participants data
	match = MatchFunctions.adjustMapData(match)
	match = MatchFunctions.getScoreFromMaps(match)

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = MatchFunctions.getOpponents(match)
	match = MatchFunctions.getTournamentVars(match)
	match = MatchFunctions.getVodStuff(match)
	match = MatchFunctions.getExtraData(match)

	return match
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param record table
---@param timestamp number
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

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
	if Logic.isNotEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

---@param opponents table[]
---@param winner string|number
---@param finished boolean
---@return table[]
---@return string|number
function CustomMatchGroupInput.setPlacement(opponents, winner, finished)
	local lastScore = NO_SCORE
	local lastPlacement = NO_SCORE
	local counter = 0
	for scoreIndex, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.placementSortFunction) do
		local score = tonumber(opp.score)
		counter = counter + 1
		if counter == 1 and Logic.isEmpty(winner) and finished then
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

---@param tbl table
---@param key1 string|number
---@param key2 string|number
---@return boolean
function CustomMatchGroupInput.placementSortFunction(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score) or NO_SCORE
	local value2 = tonumber(tbl[key2].score) or NO_SCORE
	return value1 > value2
end

--
-- match related functions
--
---@param match table
---@return table
function MatchFunctions.adjustMapData(match)
	local opponents = Array.mapIndexes(function(idx) return match['opponent' .. idx] end)
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local scores
		Table.mergeInto(map, MatchGroupInput.readDate(map.date))
		map = MapFunctions.getParticipants(map, opponents)
		map = MapFunctions.getOpponentStats(map, opponents, mapIndex)
		map, scores = MapFunctions.getScoresAndWinner(map, match.scoreSettings)
		map = MapFunctions.getExtraData(map, scores)

		if map.map == DUMMY_MAP_NAME then
			map.map = ''
		end

		match[key] = map
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.parseSetting(match)
	-- Score Settings
	match.scoreSettings = {
		kill = tonumber(match.p_kill) or 1,
		matchPointThreadhold = tonumber(match.matchpoint),
	}

	Table.mergeInto(match.scoreSettings, Array.mapIndexes(function(idx)
		return match['opponent' .. idx] and (tonumber(match['p' .. idx]) or 0) or nil
	end))

	-- Up/Down colors
	local function splitAndTrim(s, pattern)
		if not s then
			return {}
		end
		return Array.map(mw.text.split(s, pattern), String.trim)
	end

	match.statusSettings = Array.flatMap(splitAndTrim(match.bg, ','), function (status)
		local placements, color = unpack(splitAndTrim(status, '='))
		local pStart, pEnd = unpack(splitAndTrim(placements, '-'))
		local pStartNumber = tonumber(pStart) --[[@as integer]]
		local pEndNumber = tonumber(pEnd) or pStartNumber
		return Array.map(Array.range(pStartNumber, pEndNumber), function()
			return color
		end)
	end)

	return match
end

--- Calculate the points based on the map results
---@param match table
---@return table
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
			match['opponent' .. index].score = (newScores[index] or 0) + (match['opponent' .. index].pointmodifier or 0)
		end
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {
		stats = match.stats,
	}

	return match
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	match.extradata = {
		scoring = match.scoreSettings,
		status = match.statusSettings,
	}

	return match
end

---@param match table
---@return table
function MatchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
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
			assert(Opponent.isType(opponent.type), 'Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
			if opponent.type == Opponent.team then
				if Logic.isNotEmpty(opponent.name) then
					match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
						resolveRedirect = true,
						applyUnderScores = true,
						maxNumPlayers = MAX_NUM_PLAYERS,
					})
				end
			end

			opponent.extradata = opponent.extradata or {}
			opponent.extradata.startingpoints = tonumber(opponent.pointmodifier)

			opponents[opponentIndex] = opponent
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
		local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT or SECONDS_UNTIL_FINISHED_NOT_EXACT
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if Logic.isNotEmpty(match.winner) or Logic.readBool(match.finished) then
		match.finished = true
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	if match.finished then
		opponents = MatchFunctions.setBgForOpponents(opponents, match.statusSettings)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end

	return match
end

---@param opponents table
---@param statusSettings table
---@return table
function MatchFunctions.setBgForOpponents(opponents, statusSettings)
	Array.forEach(opponents, function(opponent)
		opponent.extradata.bg = statusSettings[opponent.placement]
	end)
	return opponents
end

--
-- map related functions
--

-- Parse extradata information
---@param map table
---@param scores table[]
---@return table
function MapFunctions.getExtraData(map, scores)
	map.extradata = {
		dateexact = map.dateexact,
		comment = map.comment,
		opponents = scores,
	}

	return map
end

-- Parse participant information
---@param map table
---@param opponents table[]
---@return table
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

---@param player table
---@param opponentIndex integer
---@param players table[]?
---@param participants table
---@return table
function MapFunctions.attachToParticipant(player, opponentIndex, players, participants)
	player.player = mw.ext.TeamLiquidIntegration.resolve_redirect(player.player or ''):gsub(' ', '_')
	for playerIndex, item in pairs(players or {}) do
		if player.player == item.name then
			participants[opponentIndex .. '_' .. playerIndex] = player
			break
		end
	end

	return participants
end

---@param map table
---@param opponents table[]
---@param idx integer
---@return table
function MapFunctions.getOpponentStats(map, opponents, idx)
	for oppIdx, opponent in pairs(opponents) do
		map['t'.. oppIdx ..'data'] = Json.parseIfString(opponent['m' .. idx])
	end

	return map
end

---Calculate Score and Winner of the map
---@param map table
---@param scoreSettings table
---@return table
---@return table
function MapFunctions.getScoresAndWinner(map, scoreSettings)
	map.scores = {}
	local indexedScores = {}
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local opponentData = map['t' .. opponentIndex .. 'data']
		if not opponentData then
			break
		end
		local scoreBreakdown = {}

		local placement, kills = tonumber(opponentData[1]), tonumber(opponentData[2])
		if placement and kills then
			scoreBreakdown.placePoints = scoreSettings[placement] or 0
			scoreBreakdown.killPoints = kills * scoreSettings.kill
			scoreBreakdown.kills = kills
			scoreBreakdown.totalPoints = scoreBreakdown.placePoints + scoreBreakdown.killPoints
		end
		local opponent = {
			status = STATUS_SCORE,
			scoreBreakdown = scoreBreakdown,
			placement = placement,
			score = scoreBreakdown.totalPoints,
		}

		if opponentData[1] == '-' then
			opponent.placement = NO_SCORE
		end

		table.insert(map.scores, opponent.score or 0)
		indexedScores[opponentIndex] = opponent
	end

	map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)

	return map, indexedScores
end

return CustomMatchGroupInput
