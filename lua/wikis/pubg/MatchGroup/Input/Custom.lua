---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

---@class PubgMatchParser: MatchParserInterface
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		applyUnderScores = true,
		maxNumPlayers = 4,
	},
	DEFAULT_MODE = 'team',
	getBestOf = MatchGroupInputUtil.getBestOf,
}

---@class PubgMapParser: MapParserInterface
local MapFunctions = {}

---@class PubgFfaMatchParser: FfaMatchParserInterface
local FfaMatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		applyUnderScores = true,
		maxNumPlayers = 4,
	},
	DEFAULT_MODE = 'team'
}

---@class PubgFfaMapParser: FfaMapParserInterface
local FfaMapFunctions = {}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
end

--- Normal 2-opponent Match

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

---@param match table
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

--- FFA Match

---@param match table
---@param opponents MGIParsedOpponent[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents MGIParsedOpponent[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FfaMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param mapInput table
---@return table
function FfaMapFunctions.getMap(mapInput)
	if Logic.isEmpty(mapInput.tournamentid) or Logic.isEmpty(mapInput.matchid) then
		return mapInput
	end
	local tournamentData = mw.ext.PUBGDB.tournament(mapInput.tournamentid)
	assert(tournamentData and type(tournamentData) == 'table', '|tournamentid=' .. mapInput.tournamentid .. ' could not be retrieved.')
	local matchInfo = Array.find(tournamentData, function (element)
		return element.pubgdbt_match_id == mapInput.matchid
	end)
	assert(matchInfo, '|matchid=' .. mapInput.matchid .. ' could not be found with |tournamentid=' .. mapInput.tournamentid)
	local mapData = mw.ext.PUBGDB.match(mapInput.matchid)
	assert(mapData and type(mapData) == 'table', '|matchid=' .. mapInput.matchid .. ' could not be retrieved.')

	local _, playersByTeam = Array.groupBy(
		mapData,
		function (player)
			local teamSeparatorIndex = player.pubgdbm_name:find('_')
			local teamName = teamSeparatorIndex and player.pubgdbm_name:sub(1, teamSeparatorIndex - 1) or player.pubgdbmr_name
			return Logic.nilIfEmpty(teamName)
		end
	)

	return Table.merge(
		mapInput,
		{
			date = matchInfo.pubgdbt_match_timestamp,
			finished = true,
			teams = playersByTeam
		}
	)
end

---@param map table
---@param mapIndex integer
---@param scoreSettings table
---@param matchOpponent MGIParsedOpponent
function FfaMapFunctions.readMapOpponent(map, mapIndex, scoreSettings, matchOpponent)
	if not map.teams then
		return MatchGroupInputUtil.makeBattleRoyaleMapOpponentDetails(
			Json.parseIfString(matchOpponent['m' .. mapIndex]), scoreSettings
		)
	end
	local teamPrefix = Logic.emptyOr(matchOpponent['prefix'], matchOpponent.name)
	local teamData = map.teams[teamPrefix] --[[@as PUBGDBMatchPlayer[] ]]

	if Logic.isEmpty(teamData) then
		return {}
	end
	local mapOpponent = MatchGroupInputUtil.makeBattleRoyaleMapOpponentDetails({
		teamData[1].pubgdbm_win_place,
		Array.reduce(teamData, function (aggregate, playerData)
			return aggregate + tonumber(playerData.pubgdbm_kills)
		end, 0)
	}, scoreSettings)
	mapOpponent.players = MatchGroupInputUtil.parseMapPlayers(
		matchOpponent.match2players,
		teamData,
		function (playerIndex)
			local playerData = teamData[playerIndex]
			if Logic.isEmpty(playerData) then
				return
			end
			local separatorIndex = playerData.pubgdbm_name:find('_')
			return {name = separatorIndex and playerData.pubgdbm_name:sub(separatorIndex + 1)}
		end,
		function (playerIndex, playerIdData, playerInputData)
			local playerData = teamData[playerIndex]
			return {
				player = playerIdData.name or playerInputData.link or playerInputData.name,
				displayName = playerIdData.displayname or playerInputData.name,
				kills = tonumber(playerData.pubgdbm_kills)
			}
		end
	)
	return mapOpponent
end

return CustomMatchGroupInput
