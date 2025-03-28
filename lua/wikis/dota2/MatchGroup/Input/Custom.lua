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
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local DUMMY_MAP = 'default'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = false,
	maxNumPlayers = 15,
}
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

---@class Dota2MapParserInterface
---@field getMap fun(mapInput: table): table
---@field getLength fun(map: table): string?
---@field getSide fun(map: table, opponentIndex: integer): string?
---@field getObjectives fun(map: table, opponentIndex: integer): string?
---@field getHeroPicks fun(map: table, opponentIndex: integer): string[]?
---@field getHeroBans fun(map: table, opponentIndex: integer): string[]?
---@field getParticipants fun(map: table, opponentIndex: integer, opponent: table): table[]?
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

	local MapParser
	if options.isMatchPage then
		MapParser = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
	else
		MapParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')
	end

	return CustomMatchGroupInput.processMatchWithoutStandalone(MapParser, match)
end

---@param MapParser Dota2MapParserInterface
---@param match table
---@return table
function CustomMatchGroupInput.processMatchWithoutStandalone(MapParser, match)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, nil, MapParser)
end

---@param match table
---@param opponents table[]
---@param MapParser Dota2MapParserInterface
---@return table[]
function MatchFunctions.extractMaps(match, opponents, MapParser)
	local maps = {}
	for key, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MapParser.getMap(mapInput)
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		local dateToUse = map.date or match.date
		Table.mergeInto(map, MatchGroupInputUtil.readDate(dateToUse))

		map.map = MapFunctions.getMapName(map)
		map.length = MapParser.getLength(map)
		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])
		map.publisherid = map.matchid or String.nilIfEmpty(match['matchid' .. mapIndex])
		map.extradata = MapFunctions.getExtraData(MapParser, map, #opponents)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		map.opponents = Array.map(opponents, function(opponent, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
			local players = MapFunctions.getPlayersOfMapOpponent(MapParser, map, opponent, opponentIndex)
			return {score = score, status = status, players = players}

		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param games table[]
---@return table
function MatchFunctions.getLinks(match, games)
	---@type table<string, string|table|nil>
	local links = MatchGroupInputUtil.getLinks(match)
	links.stratz = {}
	links.dotabuff = {}
	links.datdota = {}

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
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	local isTeamGame = Array.all(opponents, function(opponent)
		return opponent.type == Opponent.team
	end)
	if Logic.readBool(Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))) and isTeamGame then
		local team1, team2 = string.gsub(opponents[1].name, ' ', '_'), string.gsub(opponents[2].name, ' ', '_')
		return tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
			'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' .. team1 ..
			'&Head_to_head_query%5Bopponent%5D=' .. team2 .. '&wpRunQuery=Run+query'
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

---@param map table
---@return string?
function MapFunctions.getMapName(map)
	if map.map == DUMMY_MAP then
		return nil
	end
	return map.map
end

---@param MapParser Dota2MapParserInterface
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(MapParser, map, opponentCount)
	local extraData = {
		publisherid = tonumber(map.publisherid),
	}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	local function prefixKeyWithTeam(key, opponentIndex)
		return 'team' .. opponentIndex .. key
	end

	for opponentIndex = 1, opponentCount do
		local opponentData = {
			objectives = MapParser.getObjectives(map, opponentIndex),
			side = MapParser.getSide(map, opponentIndex),
		}
		opponentData = Table.merge(opponentData,
			Table.map(MapParser.getHeroPicks(map, opponentIndex) or {}, function(idx, hero)
				return 'hero' .. idx, getCharacterName(hero)
			end),
			Table.map(MapParser.getHeroBans(map, opponentIndex) or {}, function(idx, hero)
				return 'ban' .. idx, getCharacterName(hero)
			end)
		)

		Table.mergeInto(extraData, Table.map(opponentData, function(key, value)
			return prefixKeyWithTeam(key, opponentIndex), value
		end))
	end

	extraData.vetophase = MapParser.getVetoPhase(map)
	Array.forEach(extraData.vetophase or {}, function(veto)
		veto.character = getCharacterName(veto.character)
	end)

	return extraData
end

---@param MapParser Dota2MapParserInterface
---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(MapParser, map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	local participantList = MapParser.getParticipants(map, opponentIndex, opponent) or {}
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		participantList,
		function (playerIndex)
			local participant = participantList[playerIndex]
			return participant and {name = participant.player} or nil
		end,
		function(playerIndex)
			local participant = participantList[playerIndex]
			participant.character = getCharacterName(participant.character)
			return participant
		end
	)
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
