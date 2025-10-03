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

---@class ValorantPlayerOverallStats
---@field acs number[]
---@field kast number[]
---@field adr number[]
---@field kills number
---@field deaths number
---@field assists number
---@field firstKills number
---@field firstDeaths number
---@field totalRoundsPlayed number
---@field totalKastRounds number
---@field damageDealt number

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

	if processedMatch.games then
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

---@param match table
---@return table
function MatchFunctions.populateOpponentStats(match)
	Array.forEach(match.opponents, function(opponent, opponentIdx)
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.overallStats = MatchFunctions.calculateOverallStatsForOpponent(match.games, opponentIdx)
		Array.forEach(opponent.match2players, function(player)
			player.extradata = player.extradata or {}
			player.extradata.overallStats = MatchFunctions.calculateOverallStatsForPlayer(
				match.games, player, opponentIdx
			)
		end)
	end)
	return match
end

---@param maps table[]
---@param opponentIndex number
---@return table
function MatchFunctions.calculateOverallStatsForOpponent(maps, opponentIndex)
	return Array.reduce(
		Array.filter(maps, function(map)
			return map.status ~= MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED
				and map.extradata
				and map.extradata.teams
				and map.extradata.teams[opponentIndex]
		end),
		function(stats, map)
			local teamData = map.extradata.teams[opponentIndex]

			stats.firstKills = stats.firstKills + (teamData.firstKills or 0)
			stats.thrifties = stats.thrifties + (teamData.thrifties or 0)
			if teamData.postPlant then
				stats.postPlant[1] = stats.postPlant[1] + (teamData.postPlant[1] or 0)
				stats.postPlant[2] = stats.postPlant[2] + (teamData.postPlant[2] or 0)
			end
			stats.clutches = stats.clutches + (teamData.clutches or 0)

			return stats
		end,
		{
			firstKills = 0,
			thrifties = 0,
			postPlant = { 0, 0 },
			clutches = 0,
		}
	)
end

---@param maps table[]
---@param player table
---@param teamIdx number
---@return table
function MatchFunctions.calculateOverallStatsForPlayer(maps, player, teamIdx)
	local playerId = player.player
	if not playerId then return {} end

	local overallStats = {
		acs = {},
		kast = {},
		adr = {},
		kills = 0,
		deaths = 0,
		assists = 0,
		firstKills = 0,
		firstDeaths = 0,
		totalRoundsPlayed = 0,
		totalKastRounds = 0,
		damageDealt = 0,
	}
	local agents = {}

	Array.forEach(maps, function(map)
		if map.status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
			return
		end

		local mapOpponent = map.opponents[teamIdx]
		if not mapOpponent or not mapOpponent.players then
			return
		end

		local mapPlayerIndex

		local mapPlayer = Array.find(mapOpponent.players, function(playerData, playerIdx)
			mapPlayerIndex = playerIdx
			return playerData.player == playerId
		end)

		if not mapPlayer then
			return
		end

		if mapPlayer.agent then
			table.insert(agents, mapPlayer.agent)
		end
		if mapPlayer.acs then table.insert(overallStats.acs, mapPlayer.acs) end
		if mapPlayer.kast then table.insert(overallStats.kast, mapPlayer.kast) end
		if mapPlayer.adr then table.insert(overallStats.adr, mapPlayer.adr) end
		overallStats.kills = overallStats.kills + (mapPlayer.kills or 0)
		overallStats.deaths = overallStats.deaths + (mapPlayer.deaths or 0)
		overallStats.assists = overallStats.assists + (mapPlayer.assists or 0)
		overallStats.totalRoundsPlayed = overallStats.totalRoundsPlayed + (mapPlayer.totalRounds or 0)
		overallStats.totalKastRounds = overallStats.totalKastRounds + (mapPlayer.kastRounds or 0)
		overallStats.damageDealt = overallStats.damageDealt + (mapPlayer.damageDealt or 0)

		local extraDataPlayer = Array.find(map.extradata.teams[teamIdx].players, function(playerData)
			return playerData.player == playerId
		end)
		if not extraDataPlayer then
			extraDataPlayer = map.extradata.teams[teamIdx].players[mapPlayerIndex]
		end

		overallStats.firstKills = overallStats.firstKills + (extraDataPlayer.firstKills or 0)
		overallStats.firstDeaths = overallStats.firstDeaths + (extraDataPlayer.firstDeaths or 0)
	end)

	local function average(statTable)
		if #statTable == 0 then return nil end
		local sum = Array.reduce(statTable, Operator.add)
		return sum / #statTable
	end

	local function calculatePercentage(value, total)
		if total == 0 then
			return 0
		end
		return value / total * 100
	end

	return {
		teamIndex = teamIdx,
		player = player.player,
		displayName = player.displayName,
		agent = agents,
		acs = average(overallStats.acs),
		kills = overallStats.kills,
		deaths = overallStats.deaths,
		assists = overallStats.assists,
		kast = calculatePercentage(overallStats.totalKastRounds, overallStats.totalRoundsPlayed) or nil,
		adr = overallStats.damageDealt / overallStats.totalRoundsPlayed or nil,
		firstKills = overallStats.firstKills,
		firstDeaths = overallStats.firstDeaths,
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

	local rounds = extraData.rounds or {}
	extraData.teams = Array.map(Array.range(1, 2), function(teamIdx)
		local team = {}

		local originalPlayers = Array.filter(map.opponents[teamIdx].players or {}, Table.isNotEmpty)
		team.players = Array.map(originalPlayers, function(player)
			return Table.copy(player)
		end)

		team.thrifties = #Array.filter(rounds, function (round)
			return round['t' .. teamIdx .. 'side'] == round.winningSide and round.ceremony == 'Thrifty'
		end)

		team.firstKills = #Array.filter(rounds, function (round)
			return round.firstKill.byTeam == teamIdx
		end)

		Array.forEach(team.players, function (player)
			player.firstKills = #Array.filter(rounds, function (round)
				return round.firstKill.killer == player.puuid
			end)
			player.firstDeaths = #Array.filter(rounds, function (round)
				return round.firstKill.victim == player.puuid
			end)
		end)

		team.clutches = #Array.filter(rounds, function (round)
			return round['t' .. teamIdx .. 'side'] == round.winningSide and round.ceremony == 'Clutch'
		end)

		local plantedRounds = Array.filter(rounds, function (round)
			return round['t' .. teamIdx .. 'side'] == 'atk' and round.planted
		end)

		team.postPlant = {
			#Array.filter(plantedRounds, function (round)
				return round.winningSide == 'atk'
			end),
			#plantedRounds
		}

		return team
	end)

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
			if not (participant and participant.puuid) then
				return {
					player = playerIdData.name or playerInputData.link or playerInputData.name,
					displayName = playerIdData.displayname or playerInputData.name,
				}
			end

			local allRoundsData = map.round_results or {}
			local totalRoundsOnMap = #allRoundsData

			local kastValue = participant.kast
			if kastValue > 1 then
				kastValue = kastValue / 100
			end
			local kastRoundsOnMap = kastValue * totalRoundsOnMap
			local damageDealt = participant.adr * totalRoundsOnMap

			return {
				kills = participant.kills,
				deaths = participant.deaths,
				assists = participant.assists,
				acs = participant.acs,
				adr = participant.adr,
				kast = participant.kast,
				hs = participant.hs,
				totalRounds = totalRoundsOnMap,
				kastRounds = kastRoundsOnMap,
				damageDealt = damageDealt,
				player = playerIdData.name or playerInputData.link or playerInputData.name,
				displayName = playerIdData.displayname or playerInputData.name,
				puuid = participant.puuid,

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
