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
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = MatchFunctions.extractMaps(MatchParser, match, #opponents)
	match.bestof = MatchGroupInput.getBestOf(match.bestof, games)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, opponents) and MatchFunctions.calculateMatchScore(games) or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInput.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInput.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInput.getWinner(match.resulttype, winnerInput, opponents)
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
---@return table[]
function MatchFunctions.extractMaps(MatchParser, match, opponentCount)
	local maps = {}
	for key, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MatchParser.getMap(mapInput)
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if map.map == DUMMY_MAP then
			map.map = nil
		end

		map.length = MatchParser.getLength(map)
		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])
		map.participants = MapFunctions.getParticipants(MatchParser, map, opponentCount)
		map.extradata = MapFunctions.getExtraData(MatchParser, map, opponentCount)

		map.finished = MatchGroupInput.mapIsFinished(map)
		if map.finished then
			local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
				local score, status = MatchGroupInput.computeOpponentScore({
					walkover = map.walkover,
					winner = map.winner,
					opponentIndex = opponentIndex,
					score = map['score' .. opponentIndex],
				}, MapFunctions.calculateMapScore(map.winner))
				return {score = score, status = status}
			end)
			map.scores = Array.map(opponentInfo, Operator.property('score'))
			map.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInput.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInput.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInput.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
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

---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(MatchParser, map, opponentCount)
	local extraData = {
		comment = map.comment,
	}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, HeroNames)

	local function prefixKeyWithTeam(key, opponentIndex)
		return 'team' .. opponentIndex .. key
	end

	for opponentIndex = 1, opponentCount do
		local opponentData = {
			objectives = MatchParser.getObjectives(map, opponentIndex),
			side = MatchParser.getSide(map, opponentIndex),
		}
		opponentData = Table.merge(opponentData,
			Table.map(MatchParser.getHeroPicks(map, opponentIndex) or {}, function(idx, hero)
				return 'champion' .. idx, getCharacterName(hero)
			end),
			Table.map(MatchParser.getHeroBans(map, opponentIndex) or {}, function(idx, hero)
				return 'ban' .. idx, getCharacterName(hero)
			end)
		)

		Table.mergeInto(extraData, Table.map(opponentData, function(key, value)
			return prefixKeyWithTeam(key, opponentIndex), value
		end))
	end

	extraData.vetophase = MatchParser.getVetoPhase(map)
	Array.forEach(extraData.vetophase or {}, function(veto)
		veto.character = getCharacterName(veto.character)
	end)

	return extraData
end

-- Parse participant information
---@param MatchParser LeagueOfLegendsMatchParserInterface
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getParticipants(MatchParser, map, opponentCount)
	local participants = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, HeroNames)

	for opponentIndex = 1, opponentCount do
		for playerIndex, participant in ipairs(MatchParser.getParticipants(map, opponentIndex) or {}) do
			participant.character = getCharacterName(participant.character)
			participants[opponentIndex .. '_' .. playerIndex] = participant
		end
	end

	return participants
end

---@param winnerInput string|integer|nil
---@return fun(opponentIndex: integer): integer
function MapFunctions.calculateMapScore(winnerInput)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
