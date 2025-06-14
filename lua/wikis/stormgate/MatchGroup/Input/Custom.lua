---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local CharacterAliases = mw.loadData('Module:CharacterAliases')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local TBD = 'TBD'
local DEFAULT_HERO_FACTION = CharacterAliases.default.faction
local MODE_MIXED = 'mixed'

---@class StormgateParticipant
---@field player string
---@field faction string?
---@field heroes string[]?
---@field position integer?
---@field flag string?
---@field random boolean?

local CustomMatchGroupInput = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		pagifyTeamNames = true,
	},
}
local MapFunctions = {
	ADD_SUB_GROUP = true,
	BREAK_ON_EMPTY = true,
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in stormgate match2')

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchFunctions.readDate(matchArgs)
	local dateProps = MatchGroupInputUtil.readDate(matchArgs.date, {
		'match_date',
		'tournament_startdate',
		'tournament_enddate'
	})

	if dateProps.dateexact then
		Variables.varDefine('match_date', dateProps.date)
	end

	return dateProps
end

---@param opponent MGIParsedOpponent
---@param opponentIndex integer
function MatchFunctions.adjustOpponent(opponent, opponentIndex)
	opponent.extradata = opponent.extradata or {}
	Table.mergeInto(opponent.extradata, MatchFunctions.getOpponentExtradata(opponent))
	-- make sure match2players is not nil to avoid indexing nil
	opponent.match2players = opponent.match2players or {}
	Array.forEach(opponent.match2players, function(player)
		player.extradata = player.extradata or {}
		player.extradata.faction = MatchFunctions.getPlayerFaction(player)
	end)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@param opponents table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, opponents)
	return function(opponentIndex)
		local calculatedScore = MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
		if not calculatedScore then return end
		local opponent = opponents[opponentIndex]
		return calculatedScore + (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
	end
end

---@param opponent table
---@return table
function MatchFunctions.getOpponentExtradata(opponent)
	return {
		advantage = tonumber(opponent.advantage),
		penalty = tonumber(opponent.penalty),
	}
end

---@param player table
---@return string
function MatchFunctions.getPlayerFaction(player)
	return Faction.read(player.extradata.faction) or Faction.defaultFaction
end

---@param opponents {type: OpponentType}
---@return string
function MatchFunctions.getMode(opponents)
	local opponentTypes = Array.map(opponents, Operator.property('type'))
	return #Array.unique(opponentTypes) == 1 and opponentTypes[1] or MODE_MIXED
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('match_bestof'))

	if bestof then
		Variables.varDefine('match_bestof', bestof)
	end

	return bestof
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	---@type table<string, string|table|nil>
	local extradata = {}

	for prefix, mapVeto in Table.iter.pairsByPrefix(match, 'veto') do
		extradata[prefix] = mapVeto and mw.ext.TeamLiquidIntegration.resolve_redirect(mapVeto) or nil
		extradata[prefix .. 'by'] = match[prefix .. 'by']
		extradata[prefix .. 'displayname'] = match[prefix .. 'displayName']
	end

	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match('subgroup%d+header') end))

	return extradata
end

---@param game table
---@param gameIndex integer
---@param match table
---@return string?
---@return string?
function MapFunctions.getMapName(game, gameIndex, match)
	local mapName = game.map
	if mapName and mapName:upper() ~= TBD then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(game.map), game.mapDisplayName
	elseif mapName then
		return TBD
	end
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

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.literal then
		return
	elseif opponent.type == Opponent.team then
		return MapFunctions.getTeamMapPlayers(map, opponent, opponentIndex)
	end
	return MapFunctions.getPartyMapPlayers(map, opponent, opponentIndex)
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return StormgateParticipant[]
function MapFunctions.getTeamMapPlayers(mapInput, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput['t' .. opponentIndex .. 'p' .. playerIndex])
	end)

	local mapPlayers = MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local prefix = 't' .. opponentIndex .. 'p' .. playerIndex
			return {
				name = mapInput[prefix],
				link = Logic.nilIfEmpty(mapInput[prefix .. 'link']) or Variables.varDefault(mapInput[prefix] .. '_page'),
			}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local prefix = 't' .. opponentIndex .. 'p' .. playerIndex
			local faction = Faction.read(mapInput[prefix .. 'faction'])
				or (playerIdData.extradata or {}).faction or Faction.defaultFaction
			local link = playerIdData.name or playerInputData.link or playerInputData.name:gsub(' ', '_')
			return {
				faction = faction,
				player = link,
				flag = Flags.CountryName{flag = playerIdData.flag},
				position = playerIndex,
				random = Logic.readBool(mapInput[prefix .. 'random']),
				heroes = MapFunctions.readHeroes(
					mapInput[prefix .. 'heroes'],
					faction,
					link,
					Logic.readBool(mapInput[prefix .. 'noheroescheck'])
				),
			}
		end
	)

	Array.forEach(mapPlayers, function(player, playerIndex)
		if Logic.isEmpty(player) then return end
		local name = mapInput['t' .. opponentIndex .. 'p' .. player.position]
		local nameUpper = name:upper()
		local isTBD = nameUpper == TBD

		opponent.match2players[playerIndex] = opponent.match2players[playerIndex] or {
			name = isTBD and TBD or player.player,
			displayname = isTBD and TBD or name,
			flag = player.flag,
			extradata = {faction = player.faction},
		}
	end)

	return mapPlayers
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return StormgateParticipant[]
function MapFunctions.getPartyMapPlayers(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local prefix = 't' .. opponentIndex .. 'p'

	return Array.map(players, function(player, playerIndex)
		local faction = Faction.read(mapInput['t' .. opponentIndex .. 'p' .. playerIndex .. 'faction'])
			or player.extradata.faction

		return {
			faction = Faction.read(faction or player.extradata.faction),
			player = player.name,
			heroes = MapFunctions.readHeroes(
				mapInput[prefix .. playerIndex .. 'heroes'],
				faction,
				player.name,
				Logic.readBool(mapInput[prefix .. playerIndex .. 'noheroescheck'])
			),
		}
	end)
end

---@param match table
---@param map table # has map.opponents as the games opponents
---@param opponents table[]
---@return string
function MapFunctions.getMapMode(match, map, opponents)
	local playerCounts = Array.map(map.opponents or {}, MapFunctions.getMapOpponentSize)

	local modeParts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 0 then
			return Opponent.literal
		end

		return count
	end)

	return table.concat(modeParts, 'v')
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		header = map.header,
	}

	if #opponents ~= 2 then
		return extradata
	elseif Array.any(map.opponents, function(opponent) return MapFunctions.getMapOpponentSize(opponent) ~= 1 end) then
		return extradata
	end

	-- additionally store heroes in extradata so we can condition on them
	Array.forEach(map.opponents, function(opponent, opponentIndex)
		Array.forEach(opponent. players or {}, function(player)
			Array.forEach(player.heroes or {}, function(hero, heroIndex)
				extradata['opponent' .. opponentIndex .. 'hero' .. heroIndex] = hero
			end)
		end)
	end)

	---@type table[]
	local players = {
		Array.filter(Array.extractValues(map.opponents[1].players or {}), Logic.isNotEmpty)[1],
		Array.filter(Array.extractValues(map.opponents[2].players or {}), Logic.isNotEmpty)[1],
	}

	extradata.opponent1 = players[1].player
	extradata.opponent2 = players[2].player

	if map.winner ~= 1 and map.winner ~= 2 then
		return extradata
	end

	local loser = 3 - map.winner

	extradata.winnerfaction = players[map.winner].faction
	extradata.loserfaction = players[loser].faction

	return extradata
end

---@param heroesInput string?
---@param faction string?
---@param playerName string
---@param ignoreFactionHeroCheck boolean
---@return string[]?
function MapFunctions.readHeroes(heroesInput, faction, playerName, ignoreFactionHeroCheck)
	if String.isEmpty(heroesInput) then
		return
	end
	---@cast heroesInput -nil

	local heroes = Array.map(mw.text.split(heroesInput, ','), String.trim)
	return Array.map(heroes, function(hero)
		local heroData = CharacterAliases[hero:lower()]
		assert(heroData, 'Invalid hero input "' .. hero .. '"')

		local isCoreFaction = Table.includes(Faction.coreFactions, faction)
		assert(ignoreFactionHeroCheck or not isCoreFaction
			or faction == heroData.faction or heroData.faction == DEFAULT_HERO_FACTION,
			'Invalid hero input "' .. hero .. '" for faction "' .. Faction.toName(faction)
				.. '" of player "' .. playerName .. '"')

		return heroData.name
	end)
end

---@param opponent table
---@return integer
function MapFunctions.getMapOpponentSize(opponent)
	return Table.size(Array.filter(opponent.players or {}, Logic.isNotEmpty))
end

return CustomMatchGroupInput
