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
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyOpponentName = false,
	pagifyPlayerNames = true,
	maxNumPlayers = 15,
}
local DEFAULT_MODE = 'team'
local DUMMY_MAP = 'default'

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

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = MatchFunctions.extractMaps(MatchParser, match, #opponents)

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInput.computeOpponentScore(match, games, opponentIndex, opponent.score)
	end)

	match.bestof = MatchFunctions.getBestOf(match.bestof, games)
	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype, match.winner, match.walkover = MatchGroupInput.getResultTypeAndWinner(match.winner, opponents)
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
---@param opponentCount integer
---@return table
function MatchFunctions.extractMaps(MatchParser, match, opponentCount)
	local maps = {}
	for key, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MatchParser.getMap(mapInput)

		if map.map == DUMMY_MAP then
			map.map = nil
		end
		map.length = MatchParser.getLength(map)
		map.participants, map.extradata = MapFunctions.getParticipants(MatchParser, map, opponentCount)
		Table.mergeInto(map, MapFunctions.getScoresAndWinner(map, opponentCount))

		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param bestOfInput string|integer?
---@param maps table[]
---@return integer?
function MatchFunctions.getBestOf(bestOfInput, maps)
	return tonumber(bestOfInput) or #maps
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
---@param opponentCount integer
---@return table, table
function MapFunctions.getParticipants(MatchParser, map, opponentCount)
	local participants = {}
	local extradata = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, HeroNames)

	for opponentIndex = 1, opponentCount do
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
---@param opponentCount integer
---@return {finished:boolean, winner:integer?, resulttype:string?, walkover:string?, scores:integer[]}
function MapFunctions.getScoresAndWinner(map, opponentCount)
	local finished = Logic.readBool(map.finished)
	local winner = map.winner
	if winner then
		finished = true
	end

	local scores = MapFunctions.getScoreFromWinner(finished, tonumber(winner), opponentCount)

	local resultType
	if MatchGroupInput.isNotPlayedInput(winner) or MatchGroupInput.isNotPlayedInput(map.finished) then
		resultType = MatchGroupInput.RESULT_TYPE.NOT_PLAYED
		winner = nil
	end

	return {finished = finished, winner = winner, resulttype = resultType, scores = scores}
end

---@param finished boolean?
---@param winner integer?
---@param opponentCount integer
---@return table
function MapFunctions.getScoreFromWinner(finished, winner, opponentCount)
	if not finished then
		return {}
	end

	local scores = Array.map(Array.range(1, opponentCount), function() return 0 end)
	if not winner or winner < 1 or winner > opponentCount then
		return scores
	end

	scores[winner] = 1

	return scores
end

return CustomMatchGroupInput
