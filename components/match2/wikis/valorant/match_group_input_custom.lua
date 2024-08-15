---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AgentNames = require('Module:AgentNames')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local ALLOWED_VETOES = { 'decider', 'pick', 'ban', 'defaultban' }
local NOT_PLAYED_INPUTS = { 'skip', 'np', 'canceled', 'cancelled' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_MAPS = 9
local MAX_NUM_ROUNDS = 24

local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.
local DEFAULT_MODE = 'team'

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local roundFunctions = {}
local placementFunctions = {}

local CustomMatchGroupInput = {}

--- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	options = options or {}
	-- Count number of maps, check for empty maps to remove
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.removeUnsetMaps(match)
	match = matchFunctions.getScoreFromMapWinners(match)
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)
	if not options.isStandalone then
		match = matchFunctions.mergeWithStandalone(match)
	end

	return match
end

-- called from Module:Match/Subobjects
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getParticipantsData(map)

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

-- Set the field 'placement' for the two participants in the opponenets list.
-- Set the placementWinner field to the winner, and placementLoser to the other team
-- Special cases:
-- If Winner = 0, that means draw, and placementLoser isn't used. Both teams will get placementWinner
-- If Winner = -1, that mean no team won, and placementWinner isn't used. Both teams will gt placementLoser
---@param opponents table[]
---@param winner number
---@param placementWinner number
---@param placementLoser number
---@return table[]
function CustomMatchGroupInput.setPlacement(opponents, winner, placementWinner, placementLoser)
	if opponents and #opponents == 2 then
		local loserIdx
		local winnerIdx
		if winner == 1 then
			winnerIdx = 1
			loserIdx = 2
		elseif winner == 2 then
			winnerIdx = 2
			loserIdx = 1
		elseif winner == 0 then
			-- Draw; idx of winner/loser doesn't matter
			-- since loser and winner gets the same placement
			placementLoser = placementWinner
			winnerIdx = 1
			loserIdx = 2
		elseif winner == -1 then
			-- No Winner (both loses). For example if both teams DQ.
			-- idx's doesn't matter
			placementWinner = placementLoser
			winnerIdx = 1
			loserIdx = 2
		else
			error('setPlacement: Unexpected winner')
			return opponents
		end
		opponents[winnerIdx].placement = placementWinner
		opponents[loserIdx].placement = placementLoser
	end
	return opponents
end

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if Table.includes(NOT_PLAYED_INPUTS, data.finished) then
		data.resulttype = 'np'
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if placementFunctions.isDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
		elseif placementFunctions.isSpecialStatus(indexedScores) then
			data.winner = placementFunctions.getDefaultWinner(indexedScores)
			data.resulttype = 'default'
			if placementFunctions.isForfeit(indexedScores) then
				data.walkover = 'ff'
			elseif placementFunctions.isDisqualified(indexedScores) then
				data.walkover = 'dq'
			elseif placementFunctions.isWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		else
			--Valorant only has exactly 2 opponents, neither more or less
			if #indexedScores ~= 2 then
				error('Unexpected number of opponents when calculating map winner')
			end
			if tonumber(indexedScores[1].score) > tonumber(indexedScores[2].score) then
				data.winner = 1
			else
				data.winner = 2
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		end
	end
	return data, indexedScores
end

--
-- Placement related functions
--
-- function to check for draws
---@param tbl table[]
---@return boolean
function placementFunctions.isDraw(tbl)
	local last
	for _, scoreInfo in pairs(tbl) do
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

-- Check if any team has a none-standard status
---@param tbl table[]
---@return boolean
function placementFunctions.isSpecialStatus(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfeits
---@param tbl table[]
---@return boolean
function placementFunctions.isForfeit(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
---@param tbl table[]
---@return boolean
function placementFunctions.isDisqualified(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
---@param tbl table[]
---@return boolean
function placementFunctions.isWL(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
---@param tbl table[]
---@return number
function placementFunctions.getDefaultWinner(tbl)
	for index, scoreInfo in pairs(tbl) do
		if scoreInfo.status == 'W' then
			return index
		end
	end
	return -1
end

--
-- match related functions
--
---@param match table
---@return table
function matchFunctions.getBestOf(match)
	local mapCount = 0
	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			mapCount = mapCount + 1
		else
			break
		end
	end
	match.bestof = mapCount
	return match
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored in lpdb, nor displayed
-- The discardMap function will check if a map should be removed
-- Remove all maps that should be removed.
---@param match table
---@return table
function matchFunctions.removeUnsetMaps(match)
	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			if mapFunctions.discardMap(match['map'..i]) then
				match['map'..i] = nil
			end
		else
			break
		end
	end
	return match
end

-- Calculate the match scores based on the map results.
-- If it's a Best of 1, we'll take the exact score of that map
-- If it's not a Best of 1, we should count the map wins
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
---@param match table
---@return table
function matchFunctions.getScoreFromMapWinners(match)
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	local newScores = {}
	local foundScores = false

	if match.bestof == 1 and match.map1 then
		-- For best of 1, display the results of the single map
		newScores = match.map1.scores
		foundScores = true
	elseif match.bestof > 1 then
		-- For best of >1, display the map wins
		for i = 1, MAX_NUM_MAPS do
			if match['map'..i] then
				local winner = tonumber(match['map' .. i].winner)
				foundScores = true
				-- Only two opponents in Valorant
				if winner and winner > 0 and winner <= 2 then
					newScores[winner] = (newScores[winner] or 0) + 1
				end
			else
				break
			end
		end
	end
	if not opponent1.score and foundScores then
		opponent1.score = newScores[1] or 0
	end
	if not opponent2.score and foundScores then
		opponent2.score = newScores[2] or 0
	end
	match.opponent1 = opponent1
	match.opponent2 = opponent2
	return match
end

---@param match table
---@return table
function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.patch = Logic.emptyOr(match.patch, Variables.varDefault('patch'))

	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {}
	if match.vlr then match.links.vlr = 'https://vlr.gg/' .. match.vlr end

	return match
end

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = matchFunctions.getMapVeto(match),
		mvp = MatchGroupInput.readMvp(match),
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
	}
	return match
end

-- Parse the mapVeto input
---@param match table
---@return table?
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
		end
		if vetoType == 'decider' then
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
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == 'team' and not Logic.isEmpty(opponent.name) then
				match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
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
---@return table
function matchFunctions.mergeWithStandalone(match)
	local standaloneMatchId = 'MATCH_' .. match.bracketid .. '_' .. match.matchid
	local standaloneMatch = MatchGroupInput.fetchStandaloneMatch(standaloneMatchId)
	if not standaloneMatch then
		return match
	end

	-- Update Opponents from the Stanlone Match
	match.opponent1 = standaloneMatch.match2opponents[1]
	match.opponent2 = standaloneMatch.match2opponents[2]

	-- Update Maps from the Standalone Match
	for index, game in ipairs(standaloneMatch.match2games) do
		game.participants = Json.parseIfString(game.participants)
		game.extradata = Json.parseIfString(game.extradata)
		match['map' .. index] = game
	end

	-- Remove special keys (maps/games, opponents, bracketdata etc)
	for key, _ in pairs(standaloneMatch) do
		if String.startsWith(key, "match2") then
			standaloneMatch[key] = nil
		end
	end

	-- Copy all match level records which have value
	for key, value in pairs(standaloneMatch) do
		if String.isNotEmpty(value) then
			match[key] = value
		end
	end

	return match
end

--
-- map related functions
--
-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
---@param map table
---@return boolean
function mapFunctions.discardMap(map)
	if map.map == DUMMY_MAP_NAME then
		return true
	else
		return false
	end
end

---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		t1firstside = map.t1firstside,
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}
	return map
end

---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		if map['t'.. scoreIndex ..'atk'] or map['t'.. scoreIndex ..'def'] then
			score = (tonumber(map['t'.. scoreIndex ..'atk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'def']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otatk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otdef']) or 0)
		end
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
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

---@param map table
---@return table
function mapFunctions.getParticipantsData(map)
	local participants = map.participants or {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, AgentNames)
	-- fill in stats
	for o = 1, MAX_NUM_OPPONENTS do
		for player = 1, MAX_NUM_PLAYERS do
			local participant = participants[o .. '_' .. player] or {}
			local opstringBig = 'opponent' .. o .. '_p' .. player
			local opstringNormal = 't' .. o .. 'p' .. player
			local stats = map[opstringBig .. 'stats'] or map[opstringNormal]

			if stats then
				stats = Json.parse(stats)

				local kills = stats['kills']
				local deaths = stats['deaths']
				local assists = stats['assists']
				local agent = stats['agent']
				local averageCombatScore = stats['acs']
				local playerName = stats['player']

				participant.kills = Logic.isEmpty(kills) and participant.kills or kills
				participant.deaths = Logic.isEmpty(deaths) and participant.deaths or deaths
				participant.assists = Logic.isEmpty(assists) and participant.assists or assists
				participant.agent = Logic.isEmpty(agent) and participant.agent or agent
				participant.acs = Logic.isEmpty(averageCombatScore) and participant.averagecombatscore or averageCombatScore
				participant.player = Logic.isEmpty(playerName) and participant.player or playerName

				if not Table.isEmpty(participant) then
					participant.agent = getCharacterName(participant.agent)
					participants[o .. '_' .. player] = participant
					map.extradata[opstringNormal] = participant.player
					map.extradata[opstringNormal .. 'agent'] = participant.agent
				end
			end
		end
	end

	map.participants = participants

	local rounds = {}

	for i = 1, MAX_NUM_ROUNDS do
		rounds[i] = roundFunctions.getRoundData(map['round' .. i])
	end

	map.rounds = rounds
	return map
end

---@param round string
---@return table?
function roundFunctions.getRoundData(round)

	if round == nil then
		return nil
	end

	local participants = {}
	local parsedRound = Json.parse(round)

	for o = 1, MAX_NUM_OPPONENTS do
		for player = 1, MAX_NUM_PLAYERS do
			local participant = {}
			local opstring = 'opponent' .. o .. '_p' .. player
			local stats = parsedRound[opstring .. 'stats']

			if stats ~= nil then
				stats = Json.parse(stats)

				local kills = stats['kills']
				local score = stats['score']
				local weapon = stats['weapon']
				local buy = stats['buy']
				local bank = stats['bank']

				participant.kills = Logic.isEmpty(kills) and participant.kills or kills
				participant.score = Logic.isEmpty(score) and participant.score or score
				participant.weapon = Logic.isEmpty(weapon) and participant.weapon or weapon
				participant.buy = Logic.isEmpty(buy) and participant.buy or buy
				participant.bank = Logic.isEmpty(bank) and participant.bank or bank

				if not Table.isEmpty(participant) then
					participants[o .. '_' .. player] = participant
				end
			end
		end
	end

	parsedRound.buy = {
		parsedRound.buy1, parsedRound.buy2
	}

	parsedRound.bank = {
		parsedRound.bank1, parsedRound.bank2
	}

	parsedRound.kills = {
		parsedRound.kills1, parsedRound.kills2
	}

	parsedRound.participants = participants
	return parsedRound
end

return CustomMatchGroupInput
