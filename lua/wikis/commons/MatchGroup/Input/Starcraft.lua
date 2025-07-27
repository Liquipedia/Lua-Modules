---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local ASSUME_FINISHED_AFTER = MatchGroupInputUtil.ASSUME_FINISHED_AFTER
local NOW = os.time()
local TBD = 'TBD'
local TBA = 'TBA'
local MODE_MIXED = 'mixed'
local MODE_FFA = 'FFA'

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
local FfaMatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		pagifyTeamNames = true,
	},
}
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function StarcraftMatchGroupInput.processMatch(match, options)
	local cancelled = Logic.readBool(Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament')))
	if cancelled then
		match.finished = match.finished or 'skip'
	end
	match.bestof = tonumber(match.bestof)

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
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
FfaMatchFunctions.readDate = MatchFunctions.readDate

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
		isarchon = tostring(Logic.readBool(opponent.isarchon)),
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
		ffa = 'false',
	}

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		MatchFunctions.getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	Array.forEach(games, function(_, subGroupIndex)
		extradata['subgroup' .. subGroupIndex .. 'header'] = Logic.nilIfEmpty(match['submatch' .. subGroupIndex .. 'header'])
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
---@return {faction: string?, player: string, position: string, flag: string?}[]
function MapFunctions.getTeamMapPlayers(mapInput, opponent, opponentIndex)
	local archonFaction = Faction.read(mapInput['t' .. opponentIndex .. 'p1race'])
		or Faction.read(mapInput['opponent' .. opponentIndex .. 'race'])
		or ((opponent.match2players[1] or {}).extradata or {}).faction
	local isArchon = MapFunctions.isArchon(mapInput, opponent, opponentIndex)

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
			local factionKey = 't' .. opponentIndex .. 'p' .. playerIndex .. 'race'
			local faction = isArchon and archonFaction or Faction.read(mapInput[factionKey])
			return {
				faction = faction or (playerIdData.extradata or {}).faction or Faction.defaultFaction,
				player = playerIdData.name or playerInputData.link or playerInputData.name:gsub(' ', '_'),
				flag = Flags.CountryName{flag = playerIdData.flag},
				position = playerIndex,
				isarchon = isArchon,
			}
		end
	)

	Array.forEach(mapPlayers, function(player, playerIndex)
		if Logic.isEmpty(player) then return end
		local name = mapInput['t' .. opponentIndex .. 'p' .. player.position]
		local nameUpper = name:upper()
		local isTBD = nameUpper == TBD or nameUpper == TBA

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
---@param opponents table[]
---@return string
function MapFunctions.getMapMode(match, map, opponents)
	local playerCounts = Array.map(map.opponents or {}, MapFunctions.getMapOpponentSize)

	local modeParts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 0 then
			return Opponent.literal
		elseif count == 2 and MapFunctions.isArchon(map, opponents[opponentIndex], opponentIndex) then
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
FfaMapFunctions.getMapMode = MapFunctions.getMapMode

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		header = map.header,
		server = map.server,
	}

	if #opponents ~= 2 then
		return extradata
	elseif Array.any(map.opponents, function(opponent) return MapFunctions.getMapOpponentSize(opponent) ~= 1 end) then
		return extradata
	end

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

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return boolean
function MapFunctions.isArchon(mapInput, opponent, opponentIndex)
	return Logic.readBool(mapInput['opponent' .. opponentIndex .. 'archon']) or
		Logic.readBool(opponent.extradata.isarchon)
end

---@param game table
---@param gameIndex table
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

---@param opponent table
---@return integer
function MapFunctions.getMapOpponentSize(opponent)
	return Table.size(Array.filter(opponent.players or {}, Logic.isNotEmpty))
end

---
--- FFA stuff
---

---@param match table
---@param numberOfOpponents integer
---@return table
function FfaMatchFunctions.parseSettings(match, numberOfOpponents)
	local settings = MatchGroupInputUtil.parseSettings(match, numberOfOpponents)
	Table.mergeInto(settings.settings, {
		noscore = Logic.readBool(match.noscore),
		showGameDetails = false,
	})
	return settings
end

---@param opponents table[]
---@return string
function FfaMatchFunctions.getMode(opponents)
	return MODE_FFA
end

---@param opponent table
---@param opponentIndex integer
---@param match table
function FfaMatchFunctions.adjustOpponent(opponent, opponentIndex, match)
	MatchFunctions.adjustOpponent(opponent, opponentIndex)
	-- set score to 0 for all opponents if it is a match without scores
	if Logic.readBool(match.noscore) then
		opponent.score = 0
	end
end

---@param opponents table[]
---@param games table[]
---@return fun(opponentIndex: integer): integer?
function FfaMatchFunctions.calculateMatchScore(opponents, games)
	return function(opponentIndex)
		local opponent = opponents[opponentIndex]
		local sum = (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
		Array.forEach(games, function(game)
			local scores = Array.map(game.opponents, Operator.property('score'))
			sum = sum + ((scores or {})[opponentIndex] or 0)
		end)
		return sum
	end
end

---@param match table
---@param opponents {score: integer?}[]
---@return boolean
function FfaMatchFunctions.matchIsFinished(match, opponents)
	if MatchGroupInputUtil.isNotPlayed(match.winner, match.finished) then
		return true
	end

	local finished = Logic.readBoolOrNil(match.finished)
	if finished ~= nil then
		return finished
	end

	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		return true
	end

	-- If enough time has passed since match started, it should be marked as finished
	local threshold = match.dateexact and ASSUME_FINISHED_AFTER.EXACT or ASSUME_FINISHED_AFTER.ESTIMATE
	if match.timestamp ~= DateExt.defaultTimestamp and (match.timestamp + threshold) < NOW then
		return true
	end

	return FfaMatchFunctions.placementHasBeenSet(opponents)
end

---@param opponents table[]
---@return boolean
function FfaMatchFunctions.placementHasBeenSet(opponents)
	return Array.all(opponents, function(opponent) return Logic.isNumeric(opponent.placement) end)
end

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function FfaMatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		ffa = 'true',
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}
end

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param match table
---@param opponent table
function FfaMatchFunctions.extendOpponentIfFinished(match, opponent)
	opponent.extradata.advances = Logic.readBool(opponent.advances)
		or (match.bestof and (opponent.score or 0) >= match.bestof)
		or opponent.placement == 1
end

---@param mapInput table
---@param mapIndex integer
---@param match table
---@return string?
---@return string?
function FfaMapFunctions.getMapName(mapInput, mapIndex, match)
	local mapName = mapInput.map
	if mapName and mapName:upper() ~= TBD then
		mapName = mw.ext.TeamLiquidIntegration.resolve_redirect(mapInput.map)
	elseif mapName then
		mapName = TBD
	end

	return mapName, mapInput.mapDisplayName
end

---@param map any
---@return string
function FfaMapFunctions.getPatch(map)
	return Variables.varDefault('tournament_patch', '')
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function FfaMapFunctions.getExtraData(match, map, opponents)
	return {
		displayname = map.mapDisplayName,
		settings = {noscore = Logic.readBool(match.noscore)},
	}
end

---@param map table
---@param matchOpponent table
---@param opponentIndex integer
---@return table
function FfaMapFunctions.readMapOpponent(map, matchOpponent, opponentIndex)
	local score, status = MatchGroupInputUtil.computeOpponentScore{
		walkover = map.walkover,
		winner = map.winner,
		opponentIndex = opponentIndex,
		score = map['score' .. opponentIndex],
	}

	return {
		placement = tonumber(map['placement' .. opponentIndex]),
		score = score,
		status = status,
		players = MapFunctions.getPlayersOfMapOpponent(map, matchOpponent, opponentIndex),
	}
end

---@param status string?
---@param winnerInput string?
---@param mapOpponents table[]
---@return integer?
function FfaMapFunctions.getMapWinner(status, winnerInput, mapOpponents)
	local placementOfOpponents = MatchGroupInputUtil.calculatePlacementOfOpponents(mapOpponents)
	Array.forEach(mapOpponents, function(opponent, opponentIndex)
		opponent.placement = placementOfOpponents[opponentIndex]
	end)

	return StarcraftMatchGroupInput._getFfAWinner(status, winnerInput, mapOpponents)
end

---@param match table
---@param map table
---@return boolean
function FfaMapFunctions.mapIsFinished(match, map)
	local finished = Logic.readBoolOrNil(map.finished)
	if finished ~= nil then
		return finished
	end

	return Array.all(Array.range(1, #map.opponents), function(opponentIndex)
		return Logic.isNotEmpty(map['placement' .. opponentIndex]) or
			Logic.isNotEmpty(map['score' .. opponentIndex])
	end)
end

---@param status string?
---@param winnerInput integer|string|nil
---@param opponents {placement: integer?, score: integer?, status: string}[]
---@return integer?
function StarcraftMatchGroupInput._getFfAWinner(status, winnerInput, opponents)
	if status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
		return nil
	elseif Logic.isNumeric(winnerInput) then
		return tonumber(winnerInput)
	elseif MatchGroupInputUtil.isDraw(opponents, winnerInput) then
		return MatchGroupInputUtil.WINNER_DRAW
	end

	local placements = Array.map(opponents, Operator.property('placement'))
	local bestPlace = Array.min(placements)

	local calculatedWinner = Array.indexOf(placements, FnUtil.curry(Operator.eq, bestPlace))

	return calculatedWinner ~= 0 and calculatedWinner or nil
end
FfaMatchFunctions.getMatchWinner = StarcraftMatchGroupInput._getFfAWinner

return StarcraftMatchGroupInput
