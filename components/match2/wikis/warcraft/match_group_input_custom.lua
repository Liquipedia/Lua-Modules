---
-- @Liquipedia
-- wiki=warcraft
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
local MapsData = mw.loadData('Module:Maps/data')
local Operator = require('Module:Operator')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local TBD = 'TBD'
local NEUTRAL_HERO_FACTION = 'neutral'
local MODE_MIXED = 'mixed'

---@class WarcraftParticipant
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
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in warcraft match2')

	match.patch = PatchAuto.retrieve{date = match.date}

	local cancelled = Logic.readBool(Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament')))
	if cancelled then
		match.finished = match.finished or 'skip'
	end

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchFunctions.readDate(matchArgs)
	local suggestedDate = Variables.varDefault('match_date')

	local tournamentStartTime = Variables.varDefault('tournament_starttimeraw')

	if matchArgs.date or (not suggestedDate and tournamentStartTime) then
		local dateProps = MatchGroupInputUtil.readDate(matchArgs.date or tournamentStartTime)
		dateProps.dateexact = Logic.nilOr(
			Logic.readBoolOrNil(matchArgs.dateexact),
			matchArgs.date and dateProps.dateexact or false
		)
		Variables.varDefine('match_date', dateProps.date)
		return dateProps
	end

	return MatchGroupInputUtil.readDate(nil, {
		'match_date',
		'tournament_startdate',
		'tournament_enddate',
	})
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
		score2 = opponent.score2,
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
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('bestof'))

	if bestof then
		Variables.varDefine('bestof', bestof)
	end

	return bestof
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	local extradata = {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}

	for prefix, mapVeto in Table.iter.pairsByPrefix(match, 'veto') do
		extradata[prefix] = (MapsData[mapVeto:lower()] or {}).name or mapVeto
		extradata[prefix .. 'by'] = match[prefix .. 'by']
	end

	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match('subgroup%d+header') end))

	return extradata
end

---@param match table
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	if #opponents ~= 2 or Array.any(opponents, function(opponent)
		return opponent.type ~= Opponent.solo or not ((opponent.match2players or {})[1] or {}).name end)
	then
		return
	end

	return (tostring(mw.uri.fullUrl('Special:RunQuery/Head-to-Head'))
		.. '?pfRunQueryFormName=Head-to-Head&Head+to+head+query%5Bplayer%5D='
		.. opponents[1].match2players[1].name
		.. '&Head_to_head_query%5Bopponent%5D='
		.. opponents[2].match2players[1].name
		.. '&wpRunQuery=Run+query'):gsub(' ', '_')
end

---@param game table
---@return string?
function MapFunctions.getMapName(game)
	return (MapsData[(game.map or ''):lower()] or {}).name or game.map
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	local finished = map.finished
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
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
---@return WarcraftParticipant[]
function MapFunctions.getTeamMapPlayers(mapInput, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput['t' .. opponentIndex .. 'p' .. playerIndex])
	end)

	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
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
			local faction = Faction.read(mapInput[prefix .. 'race'])
				or (playerIdData.extradata or {}).faction or Faction.defaultFaction
			local link = playerIdData.name or playerInputData.link or playerInputData.name:gsub(' ', '_')
			return {
				faction = faction,
				player = link,
				flag = Flags.CountryName(playerIdData.flag),
				position = playerIndex,
				random = Logic.readBool(mapInput[prefix .. 'random']),
				heroes = MapFunctions.readHeroes(
					mapInput[prefix .. 'heroes'],
					faction,
					link,
					Logic.readBool(mapInput[prefix .. 'heroesNoCheck'])
				),
			}
		end
	)

	--- fill up with empty tables to not have gaps
	Array.forEach(opponent.match2players, function(_, playerIndex)
		participants[playerIndex] = participants[playerIndex] or {}
	end)

	Array.forEach(unattachedParticipants, function(participant)
		local name = mapInput['t' .. opponentIndex .. 'p' .. participant.position]
		local nameUpper = name:upper()
		local isTBD = nameUpper == TBD

		table.insert(opponent.match2players, {
			name = isTBD and TBD or participant.player,
			displayname = isTBD and TBD or name,
			flag = participant.flag,
			extradata = {faction = participant.faction},
		})
		participants[#opponent.match2players] = participant
	end)

	return participants
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return WarcraftParticipant[]
function MapFunctions.getPartyMapPlayers(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	-- resolve the aliases in case they are used
	local prefix = 't' .. opponentIndex .. 'p'
	mapInput[prefix .. '1race'] = Logic.emptyOr(mapInput[prefix .. '1race'], mapInput['race' .. opponentIndex])
	mapInput[prefix .. '1heroes'] = Logic.emptyOr(mapInput[prefix .. '1heroes'], mapInput['heroes' .. opponentIndex])

	return Array.map(players, function(player, playerIndex)
		local faction = Faction.read(mapInput['t' .. opponentIndex .. 'p' .. playerIndex .. 'race'])
			or player.extradata.faction

		return {
			faction = Faction.read(faction or player.extradata.faction),
			player = player.name,
			heroes = MapFunctions.readHeroes(
				mapInput[prefix .. playerIndex .. 'heroes'],
				faction,
				player.name,
				Logic.readBool(mapInput[prefix .. playerIndex .. 'heroesNoCheck'])
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
		comment = map.comment,
		displayname = map.mapDisplayName,
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
		Array.extractValues(map.opponents[1].players)[1],
		Array.extractValues(map.opponents[2].players)[1],
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
			or faction == heroData.faction or heroData.faction == NEUTRAL_HERO_FACTION,
			'Invalid hero input "' .. hero .. '" for race "' .. Faction.toName(faction)
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
