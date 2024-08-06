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
local DUMMY_MAP = 'default'
local NP_INPUTS = {'skip', 'np', 'canceled', 'cancelled'}
local SECONDS_UNTIL_FINISHED_EXACT = 30800
local SECONDS_UNTIL_FINISHED_NOT_EXACT = 86400

local NOW = os.time()

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

	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	local games = MatchFunctions.parseMaps(MatchParser, match)
	match.bestof = MatchFunctions.getBestOf(match.bestof, games)

	local opponents = MatchFunctions.getOpponents(match, games)
	match.finished = MatchFunctions._isFinished(match, opponents)

	if match.finished then
		match.resulttype, match.winner, match.walkover = CustomMatchGroupInput.getResultTypeAndWinner(match.winner, opponents)
		MatchGroupInput.setPlacement(opponents, match.winner, CustomMatchGroupInput.resultTypeToPlacements(match.resulttype))
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)
	match.extradata = MatchFunctions.getExtraData(match)

	match.games = games
	match.opponents = opponents

	return match
end

---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param match table
---@return table
function MatchFunctions.parseMaps(MatchParser, match)
	local maps = {}
	for key, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MatchParser.getMap(mapInput)

		if map.map == DUMMY_MAP then
			map.map = nil
		end
		map.length = MatchParser.getLength(map)
		map.participants, map.extradata = MapFunctions.getParticipants(MatchParser, map)
		Table.mergeInto(map, MapFunctions.getScoresAndWinner(map))

		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
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

---Should only be called on finished matches or maps
---@param winner integer|string
---@param opponents {score: number, status: string?}[]
---@return string? #Result Type
---@return integer? #Winner
---@return string? #Walkover
function CustomMatchGroupInput.getResultTypeAndWinner(winner, opponents)
	if type(winner) == 'string' and CustomMatchGroupInput.isNotPlayedInput(winner) then
		return MatchGroupInput.RESULT_TYPE.NOT_PLAYED
	end

	-- Calculate winner, resulttype, placements and walkover as applicable
	if MatchGroupInput.isDraw(opponents) then
		return MatchGroupInput.RESULT_TYPE.DRAW, MatchGroupInput.WINNER_DRAW

	elseif CustomMatchGroupInput.placementCheckSpecialStatus(opponents) then
		local walkoverType
		if MatchGroupInput.hasForfeit(opponents) then
			walkoverType = MatchGroupInput.WALKOVER.FORFIET
		elseif MatchGroupInput.hasDisqualified(opponents) then
			walkoverType = MatchGroupInput.WALKOVER.DISQUALIFIED
		elseif MatchGroupInput.hasDefaultWinLoss(opponents) then
			walkoverType = MatchGroupInput.WALKOVER.NO_SCORE
		end

		return MatchGroupInput.RESULT_TYPE.DEFAULT, MatchGroupInput.getDefaultWinner(opponents), walkoverType

	else
		assert(#opponents == 2, 'Unexpected number of opponents when calculating winner')
		return nil, tonumber(winner) or tonumber(opponents[1].score) > tonumber(opponents[2].score) and 1 or 2
	end
end

---@param resultType string?
---@return integer
---@return integer
function CustomMatchGroupInput.resultTypeToPlacements(resultType)
	if resultType == MatchGroupInput.RESULT_TYPE.DRAW then
		return 1, 1
	end
	return 1, 2
end

---@param input string
---@return boolean
function CustomMatchGroupInput.isNotPlayedInput(input)
	return Table.includes(NP_INPUTS, input)
end

-- Check if any opponent has a none-standard status
---@param opponents {status: string?}[]
---@return boolean
function CustomMatchGroupInput.placementCheckSpecialStatus(opponents)
	return Table.any(opponents,
		function (_, scoreinfo)
			return scoreinfo.status ~= MatchGroupInput.STATUS.SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
end

---@param bestOfInput string|integer?
---@param maps table[]
---@return integer?
function MatchFunctions.getBestOf(bestOfInput, maps)
	return tonumber(bestOfInput) or #maps
end

-- Calculate the match scores based on the map results (counting map wins)
---@param maps table[]
---@param opponentIndex integer
---@return integer
function MatchFunctions.computeMatchScoreFromMaps(maps, opponentIndex)
	return Array.reduce(maps, function(sumScore, map)
		return sumScore + (map.scores[opponentIndex] or 0)
	end, 0)
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
function MatchFunctions.getLinks(match)
	return {
		reddit = match.reddit and 'https://redd.it/' .. match.reddit or nil,
		gol = match.gol and 'https://gol.gg/game/stats/' .. match.gol .. '/page-game/' or nil,
		factor = match.factor and 'https://www.factor.gg/match/' .. match.factor or nil,
	}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInput.readMvp(match),
	}
end

---@param match table
---@param maps table[]
---@return standardOpponent[]
function MatchFunctions.getOpponents(match, maps)
	local matchHasStarted = match.dateexact and match.timestamp <= NOW
	local hasMapWinner = Table.any(maps, function(_, map) return map.winner end)

	return Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local opponent = match['opponent' .. opponentIndex]
		match['opponent' .. opponentIndex] = nil
		if Logic.isEmpty(opponent) then
			return -- TODO Investigate if we need to return a blank opponent here
		end

		CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

		if not opponent.score and matchHasStarted and hasMapWinner then
			opponent.score = MatchFunctions.computeMatchScoreFromMaps(maps, opponentIndex)
		end

		if match.walkover then
			local winner = tonumber(match.walkover) or tonumber(match.winner)
			if winner then
				opponent.score, opponent.status = MatchFunctions._opponentWalkover(match.walkover, winner == opponentIndex)
			end

		else
			opponent.score, opponent.status = MatchFunctions._parseScoreInput(opponent.score)
		end

		assert(opponent.type == Opponent.team or opponent.type == Opponent.solo or opponent.type == Opponent.literal,
			'Unsupported Opponent Type "' .. (opponent.type or '') .. '"')

		if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
			match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
				resolveRedirect = true,
				applyUnderScores = true,
				maxNumPlayers = MAX_NUM_PLAYERS,
			})
		elseif opponent.type == Opponent.solo then
			opponent.match2players = Json.parseIfString(opponent.match2players) or {}
			opponent.match2players[1].name = opponent.name
		end

		return opponent
	end)
end

---@param scoreInput string|number|nil
---@return integer? #SCORE
---@return string? #STATUS
function MatchFunctions._parseScoreInput(scoreInput)
	if not scoreInput then
		return
	end

	if Logic.isNumeric(scoreInput) then
		return tonumber(scoreInput), MatchGroupInput.STATUS.SCORE
	end

	local scoreUpperCase = string.upper(scoreInput)
	if Table.includes(MatchGroupInput.STATUS_INPUTS, scoreUpperCase) then
		return MatchGroupInput.SCORE_NOT_PLAYED, scoreUpperCase
	end
end

---@param walkoverInput string #wikicode input
---@param isWinner boolean
---@return integer? #SCORE
---@return string? #STATUS
function MatchFunctions._opponentWalkover(walkoverInput, isWinner)
	if Logic.isNumeric(walkoverInput) then
		walkoverInput = MatchGroupInput.STATUS.DEFAULT_LOSS
	end

	local walkoverUpperCase = string.upper(walkoverInput)
	if Table.includes(MatchGroupInput.STATUS_INPUTS, walkoverUpperCase) then
		return MatchGroupInput.SCORE_NOT_PLAYED, isWinner and MatchGroupInput.STATUS.DEFAULT_WIN or walkoverUpperCase
	end
end

---@param match table
---@param opponents table[]
---@return boolean
function MatchFunctions._isFinished(match, opponents)
	if Logic.readBool(match.finished) then
		return true
	end

	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		return true
	end

	-- If special status has been applied to a team
	if CustomMatchGroupInput.placementCheckSpecialStatus(opponents) then
		return true
	end

	if CustomMatchGroupInput.isNotPlayedInput(match.winner) then
		return true
	end

	if not MatchGroupInput.hasScore(opponents) then
		return false
	end

	-- Check if all/enough games have been played. If they have, mark as finished
	local firstTo = math.floor(match.bestof / 2)
	local scoreSum = 0
	for _, opponent in pairs(opponents) do
		local score = tonumber(opponent.score or 0)
		if score > firstTo then
			return true
		end
		scoreSum = scoreSum + score
	end
	if scoreSum >= match.bestof then
		return true
	end

	-- If enough time has passed since match started, it should be marked as finished
	local threshold = match.dateexact and SECONDS_UNTIL_FINISHED_EXACT
		or SECONDS_UNTIL_FINISHED_NOT_EXACT
	if match.timestamp ~= DateExt.defaultTimestamp and match.timestamp + threshold < NOW then
		return true
	end

	return false
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
	match.opponents = standaloneMatch.match2opponents

	-- Update Maps from the Standalone Match
	match.games = standaloneMatch.match2games
	for _, game in ipairs(match.games) do
		game.scores = Json.parseIfTable(game.scores)
		game.participants = Json.parseIfTable(game.participants)
		game.extradata = Json.parseIfTable(game.extradata)
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
	return {
		comment = map.comment,
		team1side = MatchParser.getSide(map, 1) or '',
		team2side = MatchParser.getSide(map, 2) or '',
		team1objectives = MatchParser.getObjectives(map, 1) or {},
		team2objectives = MatchParser.getObjectives(map, 2) or {},
	}
end

-- Parse participant information
---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param map table
---@return table, table
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

	Table.mergeInto(extradata, MapFunctions.getAdditionalExtraData(MatchParser, map))

	return participants, extradata
end

-- Calculate Score and Winner of the map
---@param map {finished:string?, winner:string?}]
---@return {finished:boolean, winner:integer?, resulttype:string?, walkover:string?, scores:integer[]}
function MapFunctions.getScoresAndWinner(map)
	local winner = tonumber(map.winner)
	local finished = Logic.readBool(map.finished)
	if winner then
		finished = true
	end

	local scores = MapFunctions.getScoreFromWinner(finished, winner)

	if not winner then
		return {finished = finished, winner = winner, scores = scores}
	end

	local resultType
	if CustomMatchGroupInput.isNotPlayedInput(map.winner) or CustomMatchGroupInput.isNotPlayedInput(map.finished) then
		resultType = MatchGroupInput.RESULT_TYPE.NOT_PLAYED
		winner = nil
	end

	return {finished = finished, winner = winner, resulttype = resultType, walkover = nil, scores = scores}
end

---@param finished boolean?
---@param winner integer?
---@return table
function MapFunctions.getScoreFromWinner(finished, winner)
	if not finished then
		return {}
	end

	local scores = Array.map(Array.range(0, MAX_NUM_OPPONENTS), function() return 0 end)
	if not winner or winner < 1 or winner > MAX_NUM_OPPONENTS then
		return scores
	end

	scores[winner] = 1

	return scores
end

return CustomMatchGroupInput
