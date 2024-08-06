---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local HeroNames = mw.loadData('Module:ChampionNames')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Opponent = Lua.import('Module:Opponent')

local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 15
local DEFAULT_MODE = 'team'
local NO_SCORE = -99
local DUMMY_MAP = 'default'
local NP_INPUTS = {'skip', 'np', 'canceled', 'cancelled'}
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400

local NOW = os.time()

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

---@class LeagueOfLegendsMatchParserInterface
---@field getMap fun(mapInput: table): table
---@field getLength fun(map: table): string?
---@field getSide fun(map: table, opponentIndex: integer): string?
---@field getObjectives fun(map: table, opponentIndex: integer): string?
---@field getHeroPicks fun(map: table, opponentIndex: integer): string[]?
---@field getHeroBans fun(map: table, opponentIndex: integer): string[]?
---@field getParticipants fun(map: table, opponentIndex: integer): table[]?
---@field getVetoPhase fun(map: table): table?

---@param match table
---@param options? {isMatchPage: boolean?}
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	options = options or {}

	local MatchParser
	if options.isMatchPage then
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
	else
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')
	end

	if not options.isMatchPage then
		-- See if this match has a standalone match (match page), if so use the data from there
		local standaloneMatchId = MatchGroupUtil.getStandaloneId(match.bracketid, match.matchid)
		local standaloneMatch = standaloneMatchId and MatchGroupInput.fetchStandaloneMatch(standaloneMatchId) or nil
		if standaloneMatch then
			return MatchFunctions.mergeWithStandalone(match, standaloneMatch)
		end
	end

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = MatchFunctions.getBestOf(match)
	match = MatchFunctions.adjustMapData(MatchParser, match)
	match = MatchFunctions.getScoreFromMapWinners(match)
	match = MatchFunctions.getOpponents(match)
	match = MatchFunctions.getTournamentVars(match)
	match = MatchFunctions.getVodStuff(match)
	match = MatchFunctions.getLinks(match)
	match = MatchFunctions.getExtraData(match)

	return match
end

---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param match table
---@return table
function MatchFunctions.adjustMapData(MatchParser, match)
	for key, mapInput in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MatchParser.getMap(mapInput)

		if map.map == DUMMY_MAP then
			map.map = nil
		end
		map.length = MatchParser.getLength(map)
		map = MapFunctions.getParticipants(MatchParser, map)
		map = MapFunctions.getScoresAndWinner(map)

		match[key] = map
	end

	return match
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param record table
---@param timestamp integer
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type integer|string?
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament date or today instead
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = Variables.varDefault('tournament_enddate')
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

CustomMatchGroupInput.processPlayer = FnUtil.identity

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if Table.includes(NP_INPUTS, data.finished) or Table.includes(NP_INPUTS, data.winner) then
		data.resulttype = MatchGroupInput.RESULT_TYPE.NOT_PLAYED
		data.finished = true

	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if MatchGroupInput.isDraw(indexedScores) then
			data.winner = 0
			data.resulttype = MatchGroupInput.RESULT_TYPE.DRAW
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, MatchGroupInput.RESULT_TYPE.DRAW)
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = MatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = MatchGroupInput.RESULT_TYPE.DEFAULT
			if MatchGroupInput.hasForfeit(indexedScores) then
				data.walkover = MatchGroupInput.WALKOVER.FORFIET
			elseif MatchGroupInput.hasDisqualified(indexedScores) then
				data.walkover = MatchGroupInput.WALKOVER.DISQUALIFIED
			elseif MatchGroupInput.hasDefaultWinLoss(indexedScores) then
				data.walkover = MatchGroupInput.WALKOVER.NO_SCORE
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, MatchGroupInput.RESULT_TYPE.DEFAULT)
		else
			local winner
			indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, nil, data.finished)
			data.winner = data.winner or winner
		end
	end

	return data, indexedScores
end

---@param opponents table[]
---@param winner integer?
---@param specialType string?
---@param isFinished boolean|string?
---@return table[]
---@return integer?
function CustomMatchGroupInput.setPlacement(opponents, winner, specialType, isFinished)
	if specialType == 'draw' then
		for key, _ in pairs(opponents) do
			opponents[key].placement = 1
		end
	elseif specialType == MatchGroupInput.RESULT_TYPE.DEFAULT then
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
			local score = tonumber(opp.score)
			counter = counter + 1
			if counter == 1 and Logic.isEmpty(winner) and isFinished then
				winner = scoreIndex
			end
			if lastScore == score then
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or lastPlacement
			else
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or counter
				lastPlacement = counter
				lastScore = score or NO_SCORE
			end
		end
	end

	return opponents, winner
end

---@param tbl table[]
---@param key1 integer
---@param key2 integer
---@return boolean
function CustomMatchGroupInput.placementSortFunction(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score or NO_SCORE) or NO_SCORE
	local value2 = tonumber(tbl[key2].score or NO_SCORE) or NO_SCORE
	return value1 > value2
end

-- Check if any opponent has a none-standard status
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckSpecialStatus(tbl)
	return Table.any(tbl,
		function (_, scoreinfo)
			return scoreinfo.status ~= MatchGroupInput.STATUS.SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
end

--
-- match related functions
--

---@param match table
---@return table
function MatchFunctions.getBestOf(match)
	if Logic.isNumeric(match.bestof) then
		match.bestof = tonumber(match.bestof)
		return match
	end
	for _, _, index in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		match.bestof = index
	end
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update an opponents result if score is not manually added and either
-- * Match has started
-- * At least one map has scores
---@param match table
---@return table
function MatchFunctions.getScoreFromMapWinners(match)
	local newScores = {}

	for _, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		for index = 1, MAX_NUM_OPPONENTS do
			newScores[index] = (newScores[index] or 0) + (map.scores[index] or 0)
		end
	end

	local hasStarted = match.dateexact and match.timestamp <= NOW
	local hasMapScore = Table.any(newScores, function(_, score) return score > 0 end)

	if not hasStarted or not hasMapScore then
		return match
	end

	for index = 1, MAX_NUM_OPPONENTS do
		match['opponent' .. index].score = match['opponent' .. index].score or newScores[index] or 0
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)

	for _, map, index in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. index])
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	match.links = {
		reddit = match.reddit and 'https://redd.it/' .. match.reddit or nil,
		gol = match.gol and 'https://gol.gg/game/stats/' .. match.gol .. '/page-game/' or nil,
		factor = match.factor and 'https://www.factor.gg/match/' .. match.factor or nil,
	}

	return match
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	match.extradata = {
		mvp = MatchGroupInput.readMvp(match),
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
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- apply status
			opponent.score = string.upper(opponent.score or '')
			if Logic.isNumeric(opponent.score) then
				opponent.score = tonumber(opponent.score)
				opponent.status = MatchGroupInput.STATUS.SCORE
				isScoreSet = true
			elseif Table.includes(MatchGroupInput.STATUS_INPUTS, opponent.score) then
				opponent.status = opponent.score
				opponent.score = MatchGroupInput.SCORE_NOT_PLAYED
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

	-- handle walkover
	match = MatchFunctions._handleWalkover(match, opponents)

	-- see if match should actually be finished if score is set
	if not Logic.readBool(match.finished) then
		match = MatchFunctions._finishMatch(match, opponents, isScoreSet)
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
---@param opponents table[]
---@return table
function MatchFunctions._handleWalkover(match, opponents)
	match.walkover = string.upper(match.walkover or '')
	if Logic.isNumeric(match.walkover) then
		local winnerIndex = tonumber(match.walkover)
		opponents = MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, MatchGroupInput.STATUS.DEFAULT_LOSS)
		opponents[winnerIndex].status = MatchGroupInput.STATUS.DEFAULT_WIN
		match.finished = true
	elseif Logic.isNumeric(match.winner) and Table.includes(MatchGroupInput.STATUS_INPUTS, match.walkover) then
		local winnerIndex = tonumber(match.winner)
		opponents = MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, match.walkover)
		opponents[winnerIndex].status = MatchGroupInput.STATUS.DEFAULT_WIN
		match.finished = true
	end

	return match
end

---@param match table
---@param opponents table[]
---@param isScoreSet boolean
---@return table
function MatchFunctions._finishMatch(match, opponents, isScoreSet)
	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		match.finished = true
		return match
	end

	-- If special status has been applied to a team
	if CustomMatchGroupInput.placementCheckSpecialStatus(opponents) then
		match.finished = true
		return match
	end

	if not isScoreSet then
		return match
	end

	-- Check if all/enough games have been played. If they have, mark as finished
	local firstTo = math.floor(match.bestof / 2)
	local scoreSum = 0
	for _, opponent in pairs(opponents) do
		local score = tonumber(opponent.score or 0)
		if score > firstTo then
			match.finished = true
			return match
		end
		scoreSum = scoreSum + score
	end
	if scoreSum >= match.bestof then
		match.finished = true
		return match
	end

	-- If enough time has passed since match started, it should be marked as finished
	local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT
		or SECONDS_UNTIL_FINISHED_NOT_EXACT
	if match.timestamp ~= DateExt.defaultTimestamp and match.timestamp + threshold < NOW then
		match.finished = true
	end

	return match
end

---@param opponents table[]
---@param walkoverType string?
---@return table[]
function MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for _, opponent in pairs(opponents) do
		opponent.score = MatchGroupInput.SCORE_NOT_PLAYED
		opponent.status = walkoverType
	end
	return opponents
end

---@param match table
---@param standaloneMatch table
---@return table
function MatchFunctions.mergeWithStandalone(match, standaloneMatch)
	match.matchPage = 'Match:ID_' .. match.bracketid .. '_' .. match.matchid

	-- Update Opponents from the Standlone Match
	match.opponent1 = standaloneMatch.match2opponents[1]
	match.opponent2 = standaloneMatch.match2opponents[2]

	-- Update Maps from the Standalone Match
	for index, game in ipairs(standaloneMatch.match2games) do
		game.scores = Json.parseIfTable(game.scores)
		game.participants = Json.parseIfTable(game.participants)
		game.extradata = Json.parseIfTable(game.extradata)
		match['map' .. index] = game
	end

	-- Copy all match level records which have value
	for key, value in pairs(standaloneMatch) do
		if Logic.isNotEmpty(value) and not String.startsWith(key, 'match2') then
			match[key] = value
		end
	end

	return match
end

-- Parse extradata information
---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param map table
---@return table
function MapFunctions.getAdditionalExtraData(MatchParser, map)
	map.extradata.comment = map.comment
	map.extradata.team1side = MatchParser.getSide(map, 1) or ''
	map.extradata.team2side = MatchParser.getSide(map, 2) or ''
	map.extradata.team1objectives = MatchParser.getObjectives(map, 1) or {}
	map.extradata.team2objectives = MatchParser.getObjectives(map, 2) or {}

	return map
end

-- Parse participant information
---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param map table
---@return table
function MapFunctions.getParticipants(MatchParser, map)
	local participants = {}
	local extradata = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, HeroNames)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local teamPrefix = 'team' .. opponentIndex

		Array.forEach(MatchParser.getHeroPicks(map, opponentIndex) or {}, function (hero, idx)
			extradata[teamPrefix .. 'champion' .. idx] = getCharacterName(hero)
		end)
		Array.forEach(MatchParser.getHeroBans(map, opponentIndex) or {}, function (hero, idx)
			extradata[teamPrefix .. 'ban' .. idx] = getCharacterName(hero)
		end)

		for playerIndex, participant in ipairs(MatchParser.getParticipants(map, opponentIndex) or {}) do
			participant.character = getCharacterName(participant.character)
			participants[opponentIndex .. '_' .. playerIndex] = participant
		end
	end

	extradata.vetophase = MatchParser.getVetoPhase(map)
	Array.forEach(extradata.vetophase or {}, function(veto)
		veto.character = getCharacterName(veto.character)
	end)

	map.participants = participants
	map.extradata = extradata

	return MapFunctions.getAdditionalExtraData(MatchParser, map)
end

-- Calculate Score and Winner of the map
---@param map table
---@return table
function MapFunctions.getScoresAndWinner(map)
	if Logic.isNotEmpty(map.winner) then
		map.finished = true
	end

	map = MapFunctions.getScoreFromWinner(map)
	map = CustomMatchGroupInput.getResultTypeAndWinner(map, map.scores)

	return map
end

---@param map table
---@return table
function MapFunctions.getScoreFromWinner(map)
	map.scores = {}
	if not Logic.readBool(map.finished) then
		return map
	end

	map.scores = Array.map(Array.range(0, MAX_NUM_OPPONENTS), function() return 0 end)
	local winner = tonumber(map.winner)

	if not winner or winner < 1 or winner > MAX_NUM_OPPONENTS then
		return map
	end

	map.scores[winner] = 1

	return map
end

return CustomMatchGroupInput
