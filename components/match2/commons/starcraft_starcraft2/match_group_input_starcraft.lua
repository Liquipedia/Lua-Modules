---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
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
local TBA = 'TBA'
local MODE_MIXED = 'mixed'

local StarcraftMatchGroupInput = {}
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

-- make these available for ffa
StarcraftMatchGroupInput.MatchFunctions = MatchFunctions
StarcraftMatchGroupInput.MapFunctions = MapFunctions

---@param match table
---@param options table?
---@return table
function StarcraftMatchGroupInput.processMatch(match, options)
	if Logic.readBool(match.ffa) then
		-- have to import here to avoid import loops
		local FfaStarcraftMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft/Ffa')
		return FfaStarcraftMatchGroupInput.processMatch(match, options)
	end

	local cancelled = Logic.readBool(Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament')))
	if cancelled then
		match.finished = match.finished or 'skip'
	end

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchFunctions.readDate(matchArgs)
	local dateProps = MatchGroupInputUtil.readDate(matchArgs.date, {
		'match_date',
		'tournament_startdate',
		'tournament_enddate',
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
		score2 = opponent.score2,
		isarchon = opponent.isarchon,
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
	return #Array.unique(opponentTypes) == 1 and opponents[1].type or MODE_MIXED
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
		ffa = 'false',
	}

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		MatchFunctions.getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	Array.forEach(games, function(_, subGroupIndex)
		extradata['subGroup' .. subGroupIndex .. 'header'] = Logic.nilIfEmpty(match['submatch' .. subGroupIndex .. 'header'])
	end)

	return extradata
end

---@param match table
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	local showH2H = Logic.readBool(Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead')))
	Variables.varDefine('headtohead', tostring(showH2H))

	if not showH2H or #opponents ~= 2 or Array.any(opponents, function(opponent)
		return opponent.type ~= Opponent.solo or not ((opponent.match2players or {})[1] or {}).name end)
	then
		return
	end

	return (tostring(mw.uri.fullUrl('Special:RunQuery/Match_history'))
		.. '?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D='
		.. opponents[1].match2players[1].name
		.. '&Head_to_head_query%5Bopponent%5D='
		.. opponents[2].match2players[1].name
		.. '&wpRunQuery=Run+query'):gsub(' ', '_')
end

---@param extradata table
---@param map string
---@param match table
---@param prefix string
---@param vetoIndex integer
function MatchFunctions.getVeto(extradata, map, match, prefix, vetoIndex)
	extradata[prefix] = map and mw.ext.TeamLiquidIntegration.resolve_redirect(map) or nil
	extradata[prefix .. 'by'] = match['vetoplayer' .. vetoIndex] or match['vetoopponent' .. vetoIndex]
	extradata[prefix .. 'displayname'] = match[prefix .. 'displayName']
end

---@param map table
---@return string?
function MapFunctions.getPatch(map)
	return map.patch or Variables.varDefault('tournament_patch', '')
end

---@param map table
---@param opponents table[]
---@param finishedInput string?
---@param winnerInput string?
---@return boolean
function MapFunctions.mapIsFinished(map, opponents, finishedInput, winnerInput)
	if MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		return true
	end

	local finished = Logic.readBoolOrNil(winnerInput)
	if finished ~= nil then
		return finished
	end

	if Logic.isNotEmpty(winnerInput) then
		return true
	end

	if Logic.isNotEmpty(map.walkover) then
		return true
	end

	if Logic.isNotEmpty(finishedInput) then
		return true
	end

	-- check for manual score inputs
	for opponentIndex = 1, #opponents do
		if String.isNotEmpty(map['score' .. opponentIndex]) then
			return true
		end
	end

	return false
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
---@return {faction: string?, player: string, position: string, flag: string?}[]
function MapFunctions.getTeamMapPlayers(mapInput, opponent, opponentIndex)
	local archonFaction = Faction.read(mapInput['t' .. opponentIndex .. 'p1race'])
		or Faction.read(mapInput['opponent' .. opponentIndex .. 'race'])
		or ((opponent.match2players[1] or {}).extradata or {}).faction
	local isArchon = MapFunctions.isArchon(mapInput, opponent, opponentIndex)

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
			local factionKey = 't' .. opponentIndex .. 'p' .. playerIndex .. 'race'
			local faction = isArchon and archonFaction or Faction.read(mapInput[factionKey])
			return {
				faction = faction or (playerIdData.extradata or {}).faction or Faction.defaultFaction,
				player = playerIdData.name or playerInputData.link or playerInputData.name:gsub(' ', '_'),
				flag = Flags.CountryName(playerIdData.flag),
				position = playerIndex,
			}
		end
	)

	Array.forEach(unattachedParticipants, function(participant)
		local name = mapInput['t' .. opponentIndex .. 'p' .. participant.position]
		local nameUpper = name:upper()
		local isTBD = nameUpper == TBD or nameUpper == TBA

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
---@return {faction: string?, player: string, position: string, flag: string?}[]
function MapFunctions.getPartyMapPlayers(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	-- resolve the aliases in case they are used
	mapInput['t' .. opponentIndex .. 'p1race'] = Logic.emptyOr(
		mapInput['t' .. opponentIndex .. 'p1race'],
		mapInput['race' .. opponentIndex],
		mapInput['opponent' .. opponentIndex .. 'race']
	)

	local archonFaction = Faction.read(mapInput['t' .. opponentIndex .. 'p1race'])
		or ((players[1] or {}).extradata or {}).faction
	local isArchon = MapFunctions.isArchon(mapInput, opponent, opponentIndex)

	return Array.map(players, function(player, playerIndex)
		local faction = isArchon and archonFaction or
			Logic.emptyOr(Faction.read(mapInput['t' .. opponentIndex .. 'p' .. playerIndex .. 'race']), player.Faction)

		return {
			faction = Faction.read(faction or player.extradata.faction),
			player = player.name,
		}
	end)
end

---@param match table
---@param map table # has map.opponents as the games opponents
---@param matchOpponents table[]
---@param mapOpponents table[]
---@return string
function MapFunctions.getMapMode(match, map, matchOpponents, mapOpponents)
	local playerCounts = Array.map(mapOpponents or {}, function(opponent)
		return Table.size(opponent.players or {})
	end)

	local modeParts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 0 then
			return Opponent.literal
		elseif count == 2 and MapFunctions.isArchon(map, matchOpponents[opponentIndex], opponentIndex) then
			return 'Archon'
		elseif count == 2 and Logic.readBool(map['opponent' .. opponentIndex .. 'duoSpecial']) then
			return '2S'
		elseif count == 4 and Logic.readBool(map['opponent' .. opponentIndex .. 'quadSpecial']) then
			return '4S'
		end

		return count
	end)

	return table.concat(modeParts, 'v')
end

---@param match table
---@param map table
---@param matchOpponents table[]
---@param mapOpponents table[]
---@param mapWinner integer?
---@return table
function MapFunctions.getExtraData(match, map, matchOpponents, mapOpponents, mapWinner)
	local extradata = {
		comment = map.comment,
		displayname = map.mapDisplayName,
		header = map.header,
		server = map.server,
	}

	if #matchOpponents ~= 2 then
		return extradata
	elseif Array.any(mapOpponents, function(mapOpponent) return Table.size(mapOpponent.players or {}) ~= 1 end) then
		return extradata
	end

	---@type table[]
	local players = {
		Array.extractValues(mapOpponents[1].players)[1],
		Array.extractValues(mapOpponents[2].players)[1],
	}

	extradata.opponent1 = players[1].player
	extradata.opponent2 = players[2].player

	if mapWinner ~= 1 and mapWinner ~= 2 then
		return extradata
	end

	local loser = 3 - mapWinner

	extradata.winnerfaction = players[mapWinner].faction
	extradata.loserfaction = players[loser].faction

	return extradata
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return boolean
function MapFunctions.isArchon(mapInput, opponent, opponentIndex)
	return Logic.readBool(mapInput['opponent' .. opponentIndex .. 'archon']) or
		Logic.readBool(opponent.extradata.isarchon)
end

---@param game table
---@return string?
function MapFunctions.getMapName(game)
	local mapName = game.map
	if mapName and mapName:upper() ~= TBD then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(game.map)
	elseif mapName then
		return TBD
	end
end

return StarcraftMatchGroupInput
