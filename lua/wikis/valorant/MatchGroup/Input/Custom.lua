---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local AgentNames = require('Module:AgentNames')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	getBestOf = MatchGroupInputUtil.getBestOf,
	DEFAULT_MODE = 'team',
	OPPONENT_CONFIG = {
		disregardTransferDates = true,
	}
}
local MapFunctions = {}

local VALORANT_REGIONS = {'eu', 'na', 'ap', 'kr', 'latam', 'br', 'pbe1', 'esports'}

---@alias ValorantSides 'atk'|'def'
---@alias ValorantRoundData{round: integer, winBy:string,
---t1side: ValorantSides, t2side: ValorantSides, winningSide: ValorantSides}

---@class ValorantMapParserInterface
---@field getMap fun(mapInput: table): table
---@field getMatchId fun(map: table): string?, string?
---@field getFirstSide fun(map: table, opponentIndex: integer, phase: 'normal'|'ot'): string?
---@field getParticipants fun(map: table, opponentIndex: integer): table[]?
---@field getScoreFromRounds fun(map: table, side: 'atk'|'def'|'otatk'|'otdef', opponentIndex: integer): integer?
---@field getMapName fun(map: table): string?
---@field getLength fun(map: table): string?
---@field getRounds fun(map: table): ValorantRoundData[]?
---@field getPatch fun(map: table): string?

---@param match table
---@param options table?
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

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, nil, MapParser)
end

--
-- match related functions
--

---@param match table
---@param opponents MGIParsedOpponent[]
---@param MapParser ValorantMapParserInterface
---@return table[]
function MatchFunctions.extractMaps(match, opponents, MapParser)
	---@type MapParserInterface
	local mapParser = {
		calculateMapScore = FnUtil.curry(MapFunctions.calculateMapScore, MapParser),
		getExtraData = FnUtil.curry(MapFunctions.getExtraData, MapParser),
		getMap = MapParser.getMap,
		getMapName = MapParser.getMapName,
		getLength = MapParser.getLength,
		getPlayersOfMapOpponent = FnUtil.curry(MapFunctions.getPlayersOfMapOpponent, MapParser),
		getPatch = MapParser.getPatch
	}

	return MatchGroupInputUtil.standardProcessMaps(match, opponents, mapParser)
end

-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param match table
---@param games table[]
---@return string?
function MatchFunctions.getPatch(match, games)
	return Logic.emptyOr(
		match.patch,
		#games > 0 and games[1].patch or nil
	)
end

--
-- map related functions
--
-- Check if a map should be discarded due to being redundant
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= nil
end

---@param MapParser ValorantMapParserInterface
---@param match table
---@param map table
---@param opponents table[]
---@return table<string, any>
function MapFunctions.getExtraData(MapParser, match, map, opponents)
	local publisherId, publisherRegion = MapParser.getMatchId(map)

	if not Table.includes(VALORANT_REGIONS, publisherRegion) then
		publisherRegion = nil
	end

	---@type table<string, any>
	local extraData = {
		t1firstside = MapParser.getFirstSide(map, 1, 'normal'),
		t1firstsideot = MapParser.getFirstSide(map, 1, 'ot'),
		t1halfs = {
			atk = MapParser.getScoreFromRounds(map, 'atk', 1),
			def = MapParser.getScoreFromRounds(map, 'def', 1),
			otatk = MapParser.getScoreFromRounds(map, 'otatk', 1),
			otdef = MapParser.getScoreFromRounds(map, 'otdef', 1),
		},
		t2halfs = {
			atk = MapParser.getScoreFromRounds(map, 'atk', 2),
			def = MapParser.getScoreFromRounds(map, 'def', 2),
			otatk = MapParser.getScoreFromRounds(map, 'otatk', 2),
			otdef = MapParser.getScoreFromRounds(map, 'otdef', 2),
		},
		rounds = MapParser.getRounds(map),
		publisherid = publisherId,
		publisherregion = publisherRegion,
	}

	for opponentIdx, opponent in ipairs(map.opponents) do
		for playerIdx, player in pairs(opponent.players) do
			extraData['t' .. opponentIdx .. 'p' .. playerIdx] = player.player
			extraData['t' .. opponentIdx .. 'p' .. playerIdx .. 'agent'] = player.agent
		end
	end

	return extraData
end

---@param MapParser ValorantMapParserInterface
---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(MapParser, map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, AgentNames)

	local participantList = MapParser.getParticipants(map, opponentIndex) or {}
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		participantList,
		function(playerIndex)
			local data = participantList[playerIndex]
			return data and {name = data.player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local participant = participantList[playerIndex]
			return {
				kills = participant.kills,
				deaths = participant.deaths,
				assists = participant.assists,
				acs = participant.acs,
				adr = participant.adr,
				kast = participant.kast,
				hs = participant.hs,
				player = playerIdData.name or playerInputData.link or playerInputData.name,
				displayName = playerIdData.displayname or playerInputData.name,

				agent = getCharacterName(participant.agent),
			}
		end
	)
end
---@param MapParser ValorantMapParserInterface
---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(MapParser, map)
	return function(opponentIndex)
		local attackScore = MapParser.getScoreFromRounds(map, 'atk', opponentIndex)
		local defenseScore = MapParser.getScoreFromRounds(map, 'def', opponentIndex)
		if not attackScore or not defenseScore then
			return
		end
		return (attackScore or 0)
			+ (defenseScore or 0)
			+ (MapParser.getScoreFromRounds(map, 'otatk', opponentIndex) or 0)
			+ (MapParser.getScoreFromRounds(map, 'otdef', opponentIndex) or 0)
	end
end

return CustomMatchGroupInput
