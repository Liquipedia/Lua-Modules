---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local AgentNames = Lua.import('Module:AgentNames', {loadData = true})
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

---@class ValorantDBGameExtended: ValorantDBGame
---@field date string?
---@field reversed boolean?
---@field vod string?

---@class ValorantMatchPageMapParser: MapParserInterface
local MapFunctions = {}

---@param mapInput {matchid: string?, region: ValorantDBRegion, reversed: boolean?, vod: string?}
---@return ValorantDBGameExtended
function MapFunctions.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.valorantdb.getDetails(mapInput.matchid, mapInput.region)

	-- Match not found on the API
	assert(
		map and type(map) == 'table',
		mapInput.matchid .. ' in region ' .. mapInput.region .. ' could not be retrieved.'
	)

	---@cast map ValorantDBGameExtended

	map.date = map.matchInfo.gameStartTime
	map.reversed = Logic.readBool(mapInput.reversed)
	-- Manually import vod from input
	map.vod = mapInput.vod

	return map
end

---@param opponentIndex 1|2
---@param reversed boolean
---@return 1|2
function MapFunctions._processOpponentIndex(opponentIndex, reversed)
	if not reversed then
		return opponentIndex
	end
	return opponentIndex == 1 and 2 or 1
end

---@param match table
---@param map ValorantDBGameExtended
---@param opponents table[]
---@return table<string, any>
function MapFunctions.getExtraData(match, map, opponents)
	local extraData = {
		t1firstside = MapFunctions._parseT1FirstSide(map.matchInfo.o1t1firstside, map.reversed),
		t1halfs = MapFunctions._parseTeamHalfs(map, 1),
		t2halfs = MapFunctions._parseTeamHalfs(map, 2),
	}

	Array.forEach(map.players, function (_, teamIndex)
		local processedIndex = MapFunctions._processOpponentIndex(teamIndex, map.reversed)
		Array.forEach(
			map.players[processedIndex],
			function (player, playerIndex)
				extraData['t' .. processedIndex .. 'p' .. playerIndex] = player.riot_id
				extraData['t' .. processedIndex .. 'p' .. playerIndex .. 'agent'] = player.agent
			end
		)
	end)

	return extraData
end
---@param map ValorantDBGameExtended
---@pram opponentIndex integer
---@return {atk: integer, def: integer, otatk: integer?, otdef: integer?}?
function MapFunctions._parseTeamHalfs(map, opponentIndex)
	local parsedIndex = MapFunctions._processOpponentIndex(opponentIndex, map.reversed)
	if not map.teams then return end
	local teamId = map.teams[parsedIndex].teamId
	local teamWins = map.matchInfo[teamId] --[[@as ValorantDBTeamScore]]
	return {
		atk = teamWins.teamatkwins,
		def = teamWins.teamdefwins,
		otatk = teamWins.teamatkotwins > 0 and teamWins.teamatkotwins or nil,
		otdef = teamWins.teamdefotwins > 0 and teamWins.teamdefotwins or nil
	}
end

---@param rawSide ValorantDBSide
---@param reversed boolean
---@return ValorantDBSide
function MapFunctions._parseT1FirstSide(rawSide, reversed)
	if not reversed then
		return rawSide
	elseif rawSide == 'atk' then
		return 'def'
	end
	return 'atk'
end

---@param map ValorantDBGameExtended
---@param opponent table
---@param opponentIndex integer
---@return table[]?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, AgentNames)

	if not map.players then return end
	local players = map.players[MapFunctions._processOpponentIndex(opponentIndex, map.reversed)]
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			return {link = players[playerIndex].riot_id}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local stats = players[playerIndex]
			return {
				kills = stats.kills,
				deaths = stats.deaths,
				assists = stats.assists,
				acs = stats.acs,
				player = playerIdData.name or playerInputData.name,
				agent = getCharacterName(stats.agent),
			}
		end
	)
end

---@param map ValorantDBGameExtended
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		local parsedIndex = MapFunctions._processOpponentIndex(opponentIndex, map.reversed)
		if not map.teams then return end
		return map.teams[parsedIndex].roundsWon
	end
end

---@param map ValorantDBGameExtended
---@return string?
function MapFunctions.getPatch(map)
	if not map.matchInfo then return end
	return map.matchInfo.gameVersion
end

---@param map ValorantDBGameExtended
---@return string?
function MapFunctions.getMapName(map)
	if not map.matchInfo then return end
	return map.matchInfo.mapId
end

---@param map ValorantDBGameExtended
---@return string?
function MapFunctions.getLength(map)
	if not map.matchInfo then return end
	return map.matchInfo.gameLengthMillis
end

return MapFunctions
