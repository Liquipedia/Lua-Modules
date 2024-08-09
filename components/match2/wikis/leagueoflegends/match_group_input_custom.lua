---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local HeroNames = mw.loadData('Module:ChampionNames')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 15
local DEFAULT_MODE = 'team'
local DUMMY_MAP = 'default'
local NP_INPUTS = {'skip', 'np', 'canceled', 'cancelled'}

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

	if not options.isMatchPage then
		-- See if this match has a standalone match (match page), if so use the data from there
		local standaloneMatchId = MatchGroupUtil.getStandaloneId(match.bracketid, match.matchid)
		local standaloneMatch = standaloneMatchId and MatchGroupInput.fetchStandaloneMatch(standaloneMatchId) or nil
		if standaloneMatch then
			return MatchGroupInput.mergeStandaloneIntoMatch(match, standaloneMatch)
		end
	end

	local MatchParser
	if options.isMatchPage then
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
	else
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')
	end

	return CustomMatchGroupInput.processMatchWithoutStandalone(MatchParser, match)
end

---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param match table
---@return table
function CustomMatchGroupInput.processMatchWithoutStandalone(MatchParser, match)
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	local games = MatchFunctions.extractMaps(MatchParser, match)
	match.bestof = MatchFunctions.getBestOf(match.bestof, games)

	local opponents = MatchFunctions.extractOpponents(match, games)
	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype, match.winner, match.walkover = CustomMatchGroupInput.getResultTypeAndWinner(match.winner, opponents)
		MatchGroupInput.setPlacement(opponents, match.winner, 1, 2)
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
function MatchFunctions.extractMaps(MatchParser, match)
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
CustomMatchGroupInput.processPlayer = FnUtil.identity

---Should only be called on finished matches or maps
---@param winner integer|string
---@param opponents {score: number, status: string}[]
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

	elseif MatchGroupInput.hasSpecialStatus(opponents) then
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

---@param input string?
---@return boolean
function CustomMatchGroupInput.isNotPlayedInput(input)
	return Table.includes(NP_INPUTS, input)
end

---@param bestOfInput string|integer?
---@param maps table[]
---@return integer?
function MatchFunctions.getBestOf(bestOfInput, maps)
	return tonumber(bestOfInput) or #maps
end

-- Calculate the match scores based on the map results (counting map wins)
---@param maps {scores: integer[]}[]
---@param opponentIndex integer
---@return integer
function MatchFunctions.computeMatchScoreFromMapScores(maps, opponentIndex)
	return Array.reduce(maps, function(sumScore, map)
		return sumScore + (map.scores[opponentIndex] or 0)
	end, 0)
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
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
---@param maps {scores: integer[], winner: integer?}[]
---@return standardOpponent[]
function MatchFunctions.extractOpponents(match, maps)
	return Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local opponent = MatchGroupInput.processOpponent(match, opponentIndex, {
			resolveRedirect = true,
			applyUnderScores = true,
			maxNumPlayers = MAX_NUM_PLAYERS,
		})
		opponent.score, opponent.status = MatchFunctions._parseOpponentScore(match, maps, opponentIndex, opponent.score)
		return opponent
	end)
end

---@param match table
---@param maps {scores: integer[], winner: integer?}[]
---@param opponentIndex integer
---@param scoreInput string|number|nil
---@return integer? #SCORE
---@return string? #STATUS
function MatchFunctions._parseOpponentScore(match, maps, opponentIndex, scoreInput)
	local matchHasStarted = MatchGroupUtil.computeMatchPhase(match) ~= 'upcoming'
	local mapHasWinner = Table.any(maps, function(_, map) return map.winner end)

	if match.walkover then
		local winner = tonumber(match.walkover) or tonumber(match.winner)
		if winner then
			return MatchFunctions._opponentWalkover(match.walkover, winner == opponentIndex)
		end
	else
		if not scoreInput and matchHasStarted and mapHasWinner then
			scoreInput = MatchFunctions.computeMatchScoreFromMapScores(maps, opponentIndex)
		end

		return MatchFunctions._parseScoreInput(scoreInput)
	end
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
	local finished = Logic.readBool(map.finished)
	local winner = map.winner
	if winner then
		finished = true
	end

	local scores = MapFunctions.getScoreFromWinner(finished, tonumber(winner))

	local resultType
	if CustomMatchGroupInput.isNotPlayedInput(winner) or CustomMatchGroupInput.isNotPlayedInput(map.finished) then
		resultType = MatchGroupInput.RESULT_TYPE.NOT_PLAYED
		winner = nil
	end

	return {finished = finished, winner = winner, resulttype = resultType, scores = scores}
end

---@param finished boolean?
---@param winner integer?
---@return table
function MapFunctions.getScoreFromWinner(finished, winner)
	if not finished then
		return {}
	end

	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function() return 0 end)
	if not winner or winner < 1 or winner > MAX_NUM_OPPONENTS then
		return scores
	end

	scores[winner] = 1

	return scores
end

return CustomMatchGroupInput
