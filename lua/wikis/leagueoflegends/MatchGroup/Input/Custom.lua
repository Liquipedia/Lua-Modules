---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local HeroNames = Lua.import('Module:ChampionNames', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = false,
	maxNumPlayers = 15,
}
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

---@class LeagueOfLegendsMapParserInterface
---@field getMap fun(mapInput: table): table
---@field getLength fun(map: table): string?
---@field getSide fun(map: table, opponentIndex: integer): string?
---@field getObjectives fun(map: table, opponentIndex: integer): string?
---@field getHeroPicks fun(map: table, opponentIndex: integer): string[]?
---@field getHeroBans fun(map: table, opponentIndex: integer): string[]?
---@field getParticipants fun(map: table, opponentIndex: integer): table[]?
---@field getVetoPhase fun(map: table): table?
---@field extendMapOpponent? fun(map: table, opponentIndex: integer): table

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

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, nil, MapParser)
end

---@param match table
---@param opponents table[]
---@param MapParser LeagueOfLegendsMapParserInterface
---@return table[]
function MatchFunctions.extractMaps(match, opponents, MapParser)
	---@type MapParserInterface
	local mapParserWrapper = {
		calculateMapScore = MapFunctions.calculateMapScore,
		getExtraData = FnUtil.curry(MapFunctions.getExtraData, MapParser),
		getMap = MapParser.getMap,
		getLength = MapParser.getLength,
		getPlayersOfMapOpponent = FnUtil.curry(MapFunctions.getPlayersOfMapOpponent, MapParser),
		extendMapOpponent = MapParser.extendMapOpponent
	}
	local maps = MatchGroupInputUtil.standardProcessMaps(match, opponents, mapParserWrapper)

	-- Legacy VOD params
	Array.forEach(maps, function (map, mapIndex)
		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])
	end)

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
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	if games[1] and games[1].opponents[1].stats then
		Array.forEach(opponents, function (opponent, opponentIndex)
			---@param name string
			---@return number?
			local function aggregateStats(name)
				return Array.reduce(
					Array.map(games, function (game)
						return (game.opponents[opponentIndex].stats or {})[name]
					end),
					Operator.nilSafeAdd
				)
			end
			opponent.extradata = {
				kills = aggregateStats('kills'),
				deaths = aggregateStats('deaths'),
				assists = aggregateStats('assists'),
				towers = aggregateStats('towers'),
				inhibitors = aggregateStats('inhibitors'),
				dragons = aggregateStats('dragons'),
				atakhans = aggregateStats('atakhans'),
				heralds = aggregateStats('heralds'),
				barons = aggregateStats('barons')
			}
			Array.forEach(games, function (game)
				if game.status == 'notplayed' then
					return
				end
				opponent.match2players = Array.map(opponent.match2players, function (player, playerIndex)
					local gamePlayerData = game.opponents[opponentIndex].players[playerIndex]
					if Logic.isEmpty(gamePlayerData) then
						return player
					end
					local parsedGameLength = Array.map(
						Array.parseCommaSeparatedString(game.length --[[@as string]], ':'), function (element)
							---Directly using tonumber as arg to Array.map causes base out of range error
							return tonumber(element)
						end
					)
					local gameLength = (parsedGameLength[1] or 0) * 60 + (parsedGameLength[2] or 0)
					player.extradata = player.extradata or {}
					player.extradata.role = player.extradata.role or gamePlayerData.role
					player.extradata.characters = Array.extend(player.extradata.characters, gamePlayerData.character)
					player.extradata.kills = Operator.nilSafeAdd(player.extradata.kills, gamePlayerData.kills)
					player.extradata.deaths = Operator.nilSafeAdd(player.extradata.deaths, gamePlayerData.deaths)
					player.extradata.assists = Operator.nilSafeAdd(player.extradata.assists, gamePlayerData.assists)
					player.extradata.damage = Operator.nilSafeAdd(player.extradata.damage, gamePlayerData.damagedone)
					player.extradata.creepscore = Operator.nilSafeAdd(player.extradata.creepscore, gamePlayerData.creepscore)
					player.extradata.gold = Operator.nilSafeAdd(player.extradata.gold, gamePlayerData.gold)
					player.extradata.gameLength = Operator.nilSafeAdd(player.extradata.gameLength, gameLength)
					return player
				end)
			end)
		end)
		---Deep copy here to work around circular reference error from LPDB storage
		opponents = Table.deepCopy(opponents)
	end

	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param MapParser LeagueOfLegendsMapParserInterface
---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(MapParser, match, map, opponents)
	local extraData = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	local function prefixKeyWithTeam(key, opponentIndex)
		return 'team' .. opponentIndex .. key
	end

	for opponentIndex = 1, #opponents do
		local opponentData = {
			objectives = MapParser.getObjectives(map, opponentIndex),
			side = MapParser.getSide(map, opponentIndex),
		}
		opponentData = Table.merge(opponentData,
			Table.map(MapParser.getHeroPicks(map, opponentIndex) or {}, function(idx, hero)
				return 'champion' .. idx, getCharacterName(hero)
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

---@param MapParser LeagueOfLegendsMapParserInterface
---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(MapParser, map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	local participantList = MapParser.getParticipants(map, opponentIndex) or {}
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		participantList,
		function (playerIndex)
			local participant = participantList[playerIndex]
			return participant and {name = participant.player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local participant = participantList[playerIndex]
			participant.player = playerIdData.name or playerInputData.link or playerInputData.name
			participant.displayName = playerIdData.displayname or playerInputData.name
			participant.character = getCharacterName(participant.character)
			return participant
		end
	)
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not map.finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
