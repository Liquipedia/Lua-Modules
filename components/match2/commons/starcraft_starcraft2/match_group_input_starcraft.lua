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
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate/Named')
local Variables = require('Module:Variables')

local DeprecatedCustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft/deprecated')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local Streams = Lua.import('Module:Links/Stream')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyOpponentName = true,
	pagifyPlayerNames = true,
}
local TBD = 'TBD'
local TBA = 'TBA'
local OPPONENT_MODE_TO_PARTIAL_MATCH_MODE = {
	solo = '1',
	duo = '2',
	trio = '3',
	quad = '4',
	team = 'team',
	literal = 'literal',
}

local StarcraftMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function StarcraftMatchGroupInput.processMatch(match, options)
	if Logic.readBool(match.ffa) then
		return DeprecatedCustomMatchGroupInput.processMatch(match, options)
	end

	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchFunctions.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = MatchFunctions.extractMaps(match, opponents)

	-- TODO: check how we can get rid of this legacy stuff ...
	Array.forEach(opponents, function(opponent, opponentIndex)
		local opponentHasWon = Table.extract(opponent, 'win')
		if not Logic.readBool(opponentHasWon) then return end
		match.winner = match.winner or opponentIndex
	end)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, opponents)
		and MatchFunctions.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, MatchFunctions.addOpponentExtradata)
	Array.forEach(opponents, MatchFunctions.applyDefaultFactionIfEmpty)

	Array.forEach(opponents, function(opponent, opponentIndex)
		MatchFunctions.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, opponent, autoScoreFunction)
	end)

	match.bestof = MatchFunctions.getBestOf(match.bestof)
	local cancelled = Logic.readBool(Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament')))
	if cancelled then
		match.finished = match.finished or 'skip'
	end

	local finishedInput = match.finished --[[@as string?]]
	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInput.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInput.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInput.setPlacement(opponents, match.winner, 1, 2)
	end

	MatchGroupInput.getCommonTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.vod = Logic.nilIfEmpty(match.vod)
	match.links = MatchFunctions.getLinks(match)
	match.extradata = MatchFunctions.getExtraData(match, #games)

	match.games = games
	match.opponents = opponents

	return match
end

---@param dateInput string?
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchFunctions.readDate(dateInput)
	local dateProps = MatchGroupInput.readDate(dateInput, {
		'matchDate',
		'tournament_startdate',
		'tournament_enddate',
	})
	if dateProps.dateexact then
		Variables.varDefine('matchDate', dateProps.date)
	end
	return dateProps
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	local subGroup = 0
	for mapKey, rawMapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local mapInput = Json.parseIfString(rawMapInput)
		local map
		map, subGroup = MapFunctions.readMap(mapInput, subGroup, #opponents)

		MapFunctions.getParticipants(map, mapInput, opponents)

		MapFunctions.getModeAndEnrichExtradata(map, mapInput, map.participants, opponents)

		map.vod = Logic.emptyOr(mapInput.vod, match['vodgame' .. mapIndex])

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInput.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param opponent table
function MatchFunctions.addOpponentExtradata(opponent)
	opponent.extradata = Table.merge(opponent.extradata or {}, {
		advantage = tonumber(opponent.advantage),
		penalty = tonumber(opponent.penalty),
		score2 = opponent.score2,
		isarchon = opponent.isarchon,
	})
end

---@param opponent table
function MatchFunctions.applyDefaultFactionIfEmpty(opponent)
	Array.forEach(opponent.match2players, function(player)
		player.extradata = Table.merge(player.extradata or {}, {faction = player.faction or Faction.defaultFaction})
	end)
end

---@param props {walkover: string|integer?, winner: string|integer?, score: string|integer?, opponentIndex: integer}
---@param opponent table
---@param autoScore? fun(opponentIndex: integer): integer?
function MatchFunctions.computeOpponentScore(props, opponent, autoScore)
	local calculatedScore, status = MatchGroupInput.computeOpponentScore(props, autoScore)

	if Logic.isNumeric(calculatedScore) and not opponent.score then
		calculatedScore = calculatedScore + (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
	end

	opponent.score = calculatedScore

	if opponent.status == MatchGroupInput.STATUS.SCORE and (props.winner == 'draw' or tonumber(props.winner) == 0) then
		opponent.status = MatchGroupInput.STATUS.DRAW
	end
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
---@return table
function MatchFunctions.getLinks(match)
	return {
		preview = match.preview,
		preview2 = match.preview2,
		interview = match.interview,
		interview2 = match.interview2,
		review = match.review,
		recap = match.recap,
		lrthread = match.lrthread,
	}
end

---@param match table
---@param numberOfGames integer
---@return table
function MatchFunctions.getExtraData(match, numberOfGames)
	local extradata = {
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
		headtohead = tostring(Logic.readBool(Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead')))),
		ffa = 'false',
	}
	Variables.varDefine('headtohead', extradata.headtohead)

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		MatchFunctions.getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	Array.forEach(Array.range(1, numberOfGames), function(subGroupIndex)
		extradata['subGroup' .. subGroupIndex .. 'header'] = Logic.nilIfEmpty(match['submatch' .. subGroupIndex .. 'header'])
	end)

	return extradata
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

---@param rawMapInput string
---@param subGroup integer
---@param opponentCount integer
---@return table
---@return integer
function MapFunctions.readMap(rawMapInput, subGroup, opponentCount)
	local mapInput = Json.parseIfString(rawMapInput)

	local map = {
		map = mapInput.map and mapInput.map ~= TBD and mw.ext.TeamLiquidIntegration.resolve_redirect(mapInput.map) or nil,
		patch = Variables.varDefault('tournament_patch', ''),
		extradata = {
			comment = mapInput.comment,
			displayname = mapInput.mapDisplayName,
			header = mapInput.header,
			server = mapInput.server,
		}
	}

	---@type string?
	local finishedInput = mapInput.finished

	map.finished = MapFunctions.isFinished(map, opponentCount)
	local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		local score, status = MatchGroupInput.computeOpponentScore({
			walkover = map.walkover,
			winner = map.winner,
			opponentIndex = opponentIndex,
			score = map['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(map.winner, map.finished))
		return {score = score, status = status}
	end)

	map.scores = Array.map(opponentInfo, Operator.property('score'))

	if map.finished then
		map.resulttype = MatchGroupInput.getResultType(mapInput.winner, finishedInput, opponentInfo)
		map.walkover = MatchGroupInput.getWalkover(map.resulttype, opponentInfo)
		map.winner = MatchGroupInput.getWinner(map.resulttype, mapInput.winner, opponentInfo)
	end

	subGroup = tonumber(mapInput.subgroup) or (subGroup + 1)

	return map, subGroup
end

---@param map table
---@param opponentCount integer
---@return boolean
function MapFunctions.isFinished(map, opponentCount)
	local finished = Logic.readBoolOrNil(map.finished)
	if finished ~= nil then
		return finished
	end

	if Logic.isNotEmpty(map.winner) then
		return true
	end

	if Logic.isNotEmpty(map.finished) then
		return true
	end

	-- check for manual score inputs
	for opponentIndex = 1, opponentCount do
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

---@param map table # the parsed map into which we fill the parse informations
---@param mapInput table # the input data
---@param opponents table[]
function MapFunctions.getParticipants(map, mapInput, opponents)
	todo

	--set: map.participants,
end

---@param opponent table
---@param playerName string
---@return integer?
function MapFunctions.getParticipantIndex(opponent, playerName)
	for playerIndex, player in ipairs(opponent.match2players) do
		if player.name == playerName then
			return playerIndex
		end
	end
end

---@param map table # the parsed map into which we fill the parse informations
---@param mapInput table # the input data
---@param participants table<string, {faction: string?, player: string, position: string, flag: string?}>
---@param opponents table[]
function MapFunctions.getModeAndEnrichExtradata(map, mapInput, participants, opponents)
	---@type (string|integer)[]
	local playerCounts = {}
	local players = {}
	for key, participant in pairs(participants) do
		local opponetIndex = key:match('(%d+)_%d+')
		playerCounts[opponetIndex] = (playerCounts[opponetIndex] or 0) + 1
		-- only relevant for 1v1 maps, hence irrelevant if we overwrite it for other map types over and over
		players[opponetIndex] = participant
	end

	---@param opponentIndex integer
	---@return boolean
	local isArchon = function(opponentIndex)
		return Logic.readBool(mapInput['opponent' .. opponentIndex .. 'archon']) or
			Logic.readBool(opponents[opponentIndex].extradata.isarchon)
	end

	playerCounts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 2 and isArchon(opponentIndex) then
			return 'Archon'
		elseif count == 2 and Logic.readBool(mapInput['opponent' .. opponentIndex .. 'duoSpecial']) then
			return '2S'
		elseif count == 4 and Logic.readBool(mapInput['opponent' .. opponentIndex .. 'quadSpecial']) then
			return '4S'
		end

		return count
	end)

	map.mode = table.concat(playerCounts, 'v')

	if map.mode ~= '1v1' then return end

	map.extradata.opponent1 = opponents[1].name
	map.extradata.opponent2 = opponents[2].name

	local winner = tonumber(map.winner)

	if winner == 1 or winner == 2 then return end

	map.extradata.winnerfaction = players[winner].faction
end




--[[

old functions (partly still to port to new stuff)

]]
---@param map table
---@param match table
---@param numberOfOpponents integer
---@return table
function StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, numberOfOpponents)
	local participants = {}
	local mapMode = ''

	for opponentIndex = 1, numberOfOpponents do
		local opponentMapMode
		if match['opponent' .. opponentIndex].type == Opponent.team then
			local players = match['opponent' .. opponentIndex].match2players
			participants, opponentMapMode = StarcraftMatchGroupInput._processTeamPlayerMapData(
				players or {},
				map,
				opponentIndex,
				participants
			)
		elseif match['opponent' .. opponentIndex].type == Opponent.literal then
			opponentMapMode = 'Literal'
		elseif
			match['opponent' .. opponentIndex].type == Opponent.duo and
			Logic.readBool(match['opponent' .. opponentIndex].extradata.isarchon)
		then
			opponentMapMode = 'Archon'
			local players = match['opponent' .. opponentIndex].match2players
			if Table.isEmpty(players) then
				break
			else
				participants = StarcraftMatchGroupInput._processArchonPlayerMapData(
					players,
					map,
					opponentIndex,
					participants
				)
			end
		else
			opponentMapMode = tonumber(OPPONENT_MODE_TO_PARTIAL_MATCH_MODE[match['opponent' .. opponentIndex].type])
			local players = match['opponent' .. opponentIndex].match2players
			if Table.isEmpty(players) then
				break
			else
				participants = StarcraftMatchGroupInput._processDefaultPlayerMapData(
					players,
					map,
					opponentIndex,
					participants
				)
			end
		end
		mapMode = mapMode .. (opponentIndex ~= 1 and 'v' or '') .. opponentMapMode

		if mapMode == '1v1' and numberOfOpponents == 2 then
			local opponentFactions, playerNameArray = StarcraftMatchGroupInput._fetchOpponentMapFactionsAndNames(participants)
			if tonumber(map.winner or 0) == 1 then
				map.extradata.winnerfaction = opponentFactions[1]
				map.extradata.loserfaction = opponentFactions[2]
			elseif tonumber(map.winner or 0) == 2 then
				map.extradata.winnerfaction = opponentFactions[2]
				map.extradata.loserfaction = opponentFactions[1]
			end
			map.extradata.opponent1 = playerNameArray[1]
			map.extradata.opponent2 = playerNameArray[2]
		end
		map.patch = Variables.varDefault('tournament_patch', '')
	end

	map.mode = mapMode

	map.participants = participants
	return map
end

---@param participants table
---@return table
---@return table
function StarcraftMatchGroupInput._fetchOpponentMapFactionsAndNames(participants)
	local opponentFactions, playerNameArray = {}, {}
	for participantKey, participantData in pairs(participants) do
		local opponentIndex = tonumber(string.sub(participantKey, 1, 1))
		-- opponentIx can not be nil due to the format of the participants keys
		---@cast opponentIndex -nil
		opponentFactions[opponentIndex] = participantData.faction
		playerNameArray[opponentIndex] = participantData.player
	end

	return opponentFactions, playerNameArray
end

---@param players table
---@param map table
---@param opponentIndex integer
---@param participants table
---@return table
function StarcraftMatchGroupInput._processDefaultPlayerMapData(players, map, opponentIndex, participants)
	map['t' .. opponentIndex .. 'p1race'] = Logic.emptyOr(
		map['t' .. opponentIndex .. 'p1race'],
		map['race' .. opponentIndex]
	)

	for playerIndex = 1, #players do
		local faction = map['t' .. opponentIndex .. 'p' .. playerIndex .. 'race']
		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = Faction.read(faction or players[playerIndex].extradata.faction) or Faction.defaultFaction,
			player = players[playerIndex].name
		}
	end

	return participants
end

---@param players table
---@param map table
---@param opponentIndex integer
---@param participants table
---@return table
function StarcraftMatchGroupInput._processArchonPlayerMapData(players, map, opponentIndex, participants)
	local faction = Logic.emptyOr(
		map['opponent' .. opponentIndex .. 'race'],
		map['race' .. opponentIndex],
		players[1].extradata.faction
	)
	participants[opponentIndex .. '_1'] = {
		faction = Faction.read(faction) or Faction.defaultFaction,
		player = players[1].name
	}

	participants[opponentIndex .. '_2'] = {
		faction = Faction.read(faction) or Faction.defaultFaction,
		player = players[2].name
	}

	return participants
end

---@param players table
---@param map table
---@param opponentIndex integer
---@param participants table
---@return table
---@return string|integer
function StarcraftMatchGroupInput._processTeamPlayerMapData(players, map, opponentIndex, participants)
	local amountOfTbds = 0
	local playerData = {}

	local numberOfPlayers = 0
	for prefix, playerInput, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
		numberOfPlayers = numberOfPlayers + 1
		if playerInput:lower() == TBD or playerInput:lower() == TBA then
			amountOfTbds = amountOfTbds + 1
		else
			local link = Logic.emptyOr(map[prefix .. 'link'], Variables.varDefault(playerInput .. '_page')) or playerInput
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(link):gsub(' ', '_')

			local faction = Logic.readBool(map['opponent' .. opponentIndex .. 'archon'])
				and Logic.emptyOr(map['t' .. opponentIndex .. 'race'], map['opponent' .. opponentIndex .. 'race'])
				or map[prefix .. 'race']

			playerData[link] = {
				faction = Faction.read(faction),
				position = playerIndex,
				displayName = playerInput,
			}
		end
	end

	local addToParticipants = function(currentPlayer, player, playerIndex)
		local faction = currentPlayer.faction or (player.extradata or {}).faction or Faction.defaultFaction

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = faction,
			player = player.name,
			position = currentPlayer.position,
			flag = Flags.CountryName(player.flag),
		}
	end

	Array.forEach(players, function(player, playerIndex)
		local currentPlayer = playerData[player.name]
		if not currentPlayer then return end

		addToParticipants(currentPlayer, player, playerIndex)
		playerData[player.name] = nil
	end)

	-- if we have players not already in the match2players insert them
	-- this is to break conditional data loops between match2 and teamCard/HDB
	Table.iter.forEachPair(playerData, function(playerLink, player)
		local faction = player.faction or Faction.defaultFaction
		table.insert(players, {
			name = playerLink,
			displayname = player.displayName,
			extradata = {faction = faction},
		})
		addToParticipants(player, players[#players], #players)
	end)

	Array.forEach(Array.range(1, amountOfTbds), function(tbdIndex)
		participants[opponentIndex .. '_' .. (#players + tbdIndex)] = {
			faction = Faction.defaultFaction,
			player = TBD:upper(),
		}
	end)

	if numberOfPlayers == 2 and Logic.readBool(map['opponent' .. opponentIndex .. 'archon']) then
		return participants, 'Archon'
	elseif numberOfPlayers == 2 and Logic.readBool(map['opponent' .. opponentIndex .. 'duoSpecial']) then
		return participants, '2S'
	elseif numberOfPlayers == 4 and Logic.readBool(map['opponent' .. opponentIndex .. 'quadSpecial']) then
		return participants, '4S'
	end

	return participants, numberOfPlayers
end

return StarcraftMatchGroupInput
