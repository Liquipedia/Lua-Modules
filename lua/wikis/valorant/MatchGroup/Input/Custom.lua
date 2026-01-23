---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local AgentNames = Lua.import('Module:AgentNames')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomMatchGroupInput = {}

---@class ValorantMatchParser: MatchParserInterface
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

---@class ValorantRoundData
---@field round integer
---@field winBy string
---@field defused boolean
---@field planted boolean
---@field firstKill {byTeam: integer?, killer: string?, victim: string?}
---@field t1side ValorantSides
---@field t2side ValorantSides
---@field winningSide ValorantSides
---@field ceremony string
---@field ceremonyFor string?

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
---@field extendMapOpponent? fun(map: table, opponentIndex: integer): table

---@class ValorantPlayerOverallStats
---@field acs integer[]
---@field kast integer[]
---@field adr integer[]
---@field kills integer
---@field deaths integer
---@field assists integer
---@field firstKills integer
---@field firstDeaths integer
---@field roundsPlayed integer
---@field totalKastRounds integer
---@field damageDealt integer

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

	local processedMatch = MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, nil, MapParser)

	if options.isMatchPage then
		MatchFunctions.populateOpponentStats(processedMatch)
	end

	return processedMatch
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
		extendMapOpponent = MapParser.extendMapOpponent,
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
---@param opponents MGIParsedOpponent[]
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

---@param match {opponents: MGIParsedOpponent[], games: table[]}
---@return table
function MatchFunctions.populateOpponentStats(match)
	Array.forEach(match.opponents, function(opponent, opponentIdx)
		opponent.extradata = Table.merge(
			opponent.extradata, MatchFunctions.calculateOverallStatsForOpponent(match.games, opponentIdx)
		)
		Array.forEach(opponent.match2players, function(player, playerIndex)
			player.extradata = player.extradata or {}
			player.extradata.overallStats = MatchFunctions.calculateOverallStatsForPlayer(
				match.games, opponentIdx, player, playerIndex
			)
		end)
	end)
	return match
end

---@param maps table[]
---@param opponentIndex integer
---@return table
function MatchFunctions.calculateOverallStatsForOpponent(maps, opponentIndex)
	local teamDataPerMap = Array.map(
		Array.filter(maps, function(map)
			return map.status ~= MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED
		end),
		function(map)
			return map.opponents[opponentIndex]
		end
	)

	local function getSumOf(key)
		return Array.reduce(Array.map(teamDataPerMap, function (teamData)
			return teamData[key] or 0
		end), Operator.add, 0)
	end

	local postPlant = Array.reduce(teamDataPerMap, function (postPlantTotals, teamData)
		if teamData.postPlant then
			postPlantTotals[1] = postPlantTotals[1] + (teamData.postPlant[1] or 0)
			postPlantTotals[2] = postPlantTotals[2] + (teamData.postPlant[2] or 0)
		end
		return postPlantTotals
	end, {0, 0})

	return {
		firstKills = getSumOf('firstKills'),
		flawless = getSumOf('flawless'),
		thrifties = getSumOf('thrifties'),
		clutches = getSumOf('clutches'),
		postPlant = postPlant,
	}
end

---@param maps table[]
---@param teamIdx integer
---@param player table
---@param playerIdx integer
---@return table
function MatchFunctions.calculateOverallStatsForPlayer(maps, teamIdx, player, playerIdx)
	local playerId = player.name
	if not playerId then return {} end

	local overallStats = {
		acs = 0,
		kills = 0,
		deaths = 0,
		assists = 0,
		firstKills = 0,
		firstDeaths = 0,
		roundsPlayed = 0,
		roundsWithKast = 0,
		damageDealt = 0,
	}
	local agents = {}

	Array.forEach(maps, function(map)
		if map.status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
			return
		end

		local mapPlayer = map.opponents[teamIdx].players[playerIdx]

		if mapPlayer.agent then
			table.insert(agents, mapPlayer.agent)
		end
		overallStats.acs = overallStats.acs + ((mapPlayer.acs or 0) * (mapPlayer.roundsPlayed or 0))
		overallStats.kills = overallStats.kills + (mapPlayer.kills or 0)
		overallStats.deaths = overallStats.deaths + (mapPlayer.deaths or 0)
		overallStats.assists = overallStats.assists + (mapPlayer.assists or 0)
		overallStats.roundsPlayed = overallStats.roundsPlayed + (mapPlayer.roundsPlayed or 0)
		overallStats.roundsWithKast = overallStats.roundsWithKast + (mapPlayer.roundsWithKast or 0)
		overallStats.damageDealt = overallStats.damageDealt + (mapPlayer.damageDealt or 0)
		overallStats.firstKills = overallStats.firstKills + (mapPlayer.firstKills or 0)
		overallStats.firstDeaths = overallStats.firstDeaths + (mapPlayer.firstDeaths or 0)
	end)

	local function calculatePercentage(value, total)
		if total == 0 then
			return 0
		end
		return value / total * 100
	end

	local kast, adr, acs
	if overallStats.roundsPlayed > 0 then
		kast = calculatePercentage(overallStats.roundsWithKast, overallStats.roundsPlayed)
		adr = overallStats.damageDealt / overallStats.roundsPlayed
		if overallStats.acs then
			acs = overallStats.acs / overallStats.roundsPlayed
		end
	end

	return {
		agent = agents,
		acs = acs,
		kills = overallStats.kills,
		deaths = overallStats.deaths,
		assists = overallStats.assists,
		kast = kast,
		adr = adr,
		firstKills = overallStats.firstKills,
		firstDeaths = overallStats.firstDeaths,
		roundsPlayed = overallStats.roundsPlayed,
	}
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
---@param opponents MGIParsedOpponent[]
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
---@param opponent MGIParsedOpponent
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

			local playerData = {
				kills = participant.kills,
				deaths = participant.deaths,
				assists = participant.assists,
				acs = participant.acs,
				adr = participant.adr,
				kast = participant.kast,
				hs = participant.hs,
				player = playerIdData.name or playerInputData.link or playerInputData.name,
				displayName = playerIdData.displayname or playerInputData.name,
				puuid = participant.puuid,
				agent = getCharacterName(participant.agent),
				firstKills = participant.firstKills,
				firstDeaths = participant.firstDeaths,
			}

			-- adds overall stats to playerData for MatchPage
			if (participant and participant.puuid) then
				local allRoundsData = map.round_results or {}
				local roundsPlayed = #allRoundsData
				local roundsWithKast = (participant.kast / 100) * roundsPlayed
				local damageDealt = participant.adr * roundsPlayed

				Table.mergeInto(playerData, {
					roundsPlayed = roundsPlayed,
					roundsWithKast = roundsWithKast,
					damageDealt = damageDealt,
				})
			end

			return playerData
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
