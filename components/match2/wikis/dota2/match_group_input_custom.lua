---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local HeroNames = mw.loadData('Module:HeroNames')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = false,
	pagifyPlayerNames = true,
	maxNumPlayers = 15,
}
local DEFAULT_MODE = 'team'
local DUMMY_MAP = 'default'

local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

---@class Dota2MatchParserInterface
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
		local standaloneMatch = standaloneMatchId and MatchGroupInputUtil.fetchStandaloneMatch(standaloneMatchId) or nil
		if standaloneMatch then
			return MatchGroupInputUtil.mergeStandaloneIntoMatch(match, standaloneMatch)
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

---@param MatchParser Dota2MatchParserInterface
---@param match table
---@return table
function CustomMatchGroupInput.processMatchWithoutStandalone(MatchParser, match)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]
	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = MatchFunctions.extractMaps(MatchParser, match, #opponents)
	match.bestof = MatchGroupInputUtil.getBestOf(match.bestof, games)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2)
	elseif MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.winner = nil
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match, games)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

---@param MatchParser Dota2MatchParserInterface
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
		map.publisherid = map.matchid or String.nilIfEmpty(match['matchid' .. mapIndex])
		map.participants = MapFunctions.getParticipants(MatchParser, map, opponentCount)
		map.extradata = MapFunctions.getExtraData(MatchParser, map, opponentCount)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished or MatchGroupInputUtil.isNotPlayed(map.winner, finishedInput) then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
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
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@param games table[]
---@return table
function MatchFunctions.getLinks(match, games)
	local links = {
		preview = match.preview,
		lrthread = match.lrthread,
		recap = match.recap,
		faceit = match.faceit and 'https://www.faceit.com/en/dota2/room/' .. match.faceit or nil,
		stratz = {},
		dotabuff = {},
		datdota = {},
	}
	Array.forEach(
		Array.filter(games, function(map) return map.publisherid ~= nil end),
		function(map, mapIndex)
			links.stratz[mapIndex] = 'https://stratz.com/match/' .. map.publisherid
			links.dotabuff[mapIndex] = 'https://www.dotabuff.com/matches/' .. map.publisherid
			links.datdota[mapIndex] = 'https://www.datdota.com/matches/' .. map.publisherid
		end
	)
	return links
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
		headtohead = match.headtohead,
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

---@param MatchParser Dota2MatchParserInterface
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(MatchParser, map, opponentCount)
	local extraData = {
		publisherid = map.publisherid or '',
		comment = map.comment,
	}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

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
				return 'hero' .. idx, getCharacterName(hero)
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
---@param MatchParser Dota2MatchParserInterface
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getParticipants(MatchParser, map, opponentCount)
	local participants = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	for opponentIndex = 1, opponentCount do
		for playerIndex, participant in ipairs(MatchParser.getParticipants(map, opponentIndex) or {}) do
			participant.character = getCharacterName(participant.character)
			participants[opponentIndex .. '_' .. playerIndex] = participant
		end
	end

	return participants
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
