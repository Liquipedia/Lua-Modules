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
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
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
local MODE_MIXED = 'mixed'

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

	Array.forEach(opponents, MatchFunctions.addOpponentExtradata)
	Array.forEach(opponents, MatchFunctions.applyDefaultFactionIfEmpty)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, opponents)
		and MatchFunctions.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		MatchFunctions.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, opponent, autoScoreFunction)
	end)

	match.mode = MatchFunctions.getMode(opponents)

	match.bestof = MatchFunctions.getBestOf(match.bestof)
	local cancelled = Logic.readBool(Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament')))
	if cancelled then
		match.finished = match.finished or 'skip'
	end

	local winnerInput = match.winner --[[@as string?]]
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

		map.participants = MapFunctions.getParticipants(mapInput, opponents)

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
		player.extradata = Table.merge(player.extradata or {}, {
			faction = (player.extradata or {}).faction or Faction.defaultFaction})
	end)
end

---@param props {walkover: string|integer?, winner: string|integer?, score: string|integer?, opponentIndex: integer}
---@param opponent table
---@param autoScore? fun(opponentIndex: integer): integer?
function MatchFunctions.computeOpponentScore(props, opponent, autoScore)
	local calculatedScore
	calculatedScore, opponent.status = MatchGroupInput.computeOpponentScore(props, autoScore)

	if Logic.isNumeric(calculatedScore) and not opponent.score then
		calculatedScore = calculatedScore + (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
	end

	opponent.score = calculatedScore

	if opponent.status == MatchGroupInput.STATUS.SCORE and (props.winner == 'draw' or tonumber(props.winner) == 0) then
		opponent.status = MatchGroupInput.STATUS.DRAW
	end
end

---@param opponents {type: OpponentType}
---@return string
function MatchFunctions.getMode(opponents)
	local firstOpponentType = opponents[1].type
	return Array.all(opponents, function(opponent) return opponent.type == firstOpponentType end)
		and firstOpponentType or MODE_MIXED
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

	subGroup = tonumber(mapInput.subgroup) or (subGroup + 1)

	local map = {
		map = mapInput.map and mapInput.map ~= TBD and mw.ext.TeamLiquidIntegration.resolve_redirect(mapInput.map) or nil,
		patch = Variables.varDefault('tournament_patch', ''),
		subgroup = subGroup,
		extradata = {
			comment = mapInput.comment,
			displayname = mapInput.mapDisplayName,
			header = mapInput.header,
			server = mapInput.server,
		}
	}

	map.finished = MapFunctions.isFinished(mapInput, opponentCount)
	local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		local score, status = MatchGroupInput.computeOpponentScore({
			walkover = mapInput.walkover,
			winner = mapInput.winner,
			opponentIndex = opponentIndex,
			score = mapInput['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(mapInput.winner, map.finished))
		return {score = score, status = status}
	end)

	map.scores = Array.map(opponentInfo, Operator.property('score'))

	if map.finished then
		map.resulttype = MatchGroupInput.getResultType(mapInput.winner, mapInput.finished, opponentInfo)
		map.walkover = MatchGroupInput.getWalkover(map.resulttype, opponentInfo)
		map.winner = MatchGroupInput.getWinner(map.resulttype, mapInput.winner, opponentInfo)
	end

	return map, subGroup
end

---@param mapInput table
---@param opponentCount integer
---@return boolean
function MapFunctions.isFinished(mapInput, opponentCount)
	local finished = Logic.readBoolOrNil(mapInput.finished)
	if finished ~= nil then
		return finished
	end

	if Logic.isNotEmpty(mapInput.winner) then
		return true
	end

	if Logic.isNotEmpty(mapInput.finished) then
		return true
	end

	-- check for manual score inputs
	for opponentIndex = 1, opponentCount do
		if String.isNotEmpty(mapInput['score' .. opponentIndex]) then
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

---@param mapInput table
---@param opponents table[]
---@return table<string, {faction: string?, player: string, position: string, flag: string?}>
function MapFunctions.getParticipants(mapInput, opponents)
	local participants = {}
	Array.forEach(opponents, function(opponent, opponentIndex)
		if opponent.type == Opponent.team then
			Table.mergeInto(participants, MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex))
			return
		elseif opponent.type == Opponent.literal then
			return
		end
		Table.mergeInto(participants, MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex))
	end)

	return participants
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, {faction: string?, player: string, position: string, flag: string?}>
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local archonFaction = Faction.read(mapInput['t' .. opponentIndex .. 'p1race'])
		or Faction.read(mapInput['opponent' .. opponentIndex .. 'race'])
		or players[1].extradata.faction
	local isArchon = MapFunctions.isArchon(mapInput, opponent, opponentIndex)

	---@type {input: string, faction: string?, link: string?}[]
	local participantsList = Array.mapIndexes(function(playerIndex)
		local prefix = 't' .. opponentIndex .. 'p' .. playerIndex

		if Logic.isEmpty(mapInput[prefix]) then return end

		return {
			input = mapInput[prefix],
			link = Logic.nilIfEmpty(mapInput[prefix .. 'link']),
			faction = isArchon and archonFaction or Faction.read(mapInput[prefix .. 'race']),
		}
	end)

	local participants = {}

	Array.forEach(participantsList, function(participantInput, position)
		local nameInput = participantInput.input

		local isTBD = nameInput:upper() == TBD or nameInput:upper() == TBA

		local link = participantInput.link or Variables.varDefault(nameInput .. '_page') or nameInput
		link = Page.pageifyLink(link) --[[@as string -- can't be nil as input isn't nil]]

		local playerIndex =  Array.indexOf(players, function(player) return player.name == link end)
		-- in case we have a TBD or a player not known in match2players inster a new player in match2players
		if isTBD or not playerIndex then
			table.insert(players, {
				name = isTBD and TBD or link,
				displayname = isTBD and TBD or nameInput,
				extradata = {faction = participantInput.faction},
			})
			playerIndex = #players
		end

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = participantInput.faction,
			player = link,
			position = position,
			flag = Flags.CountryName(players[playerIndex].flag),
		}
	end)

	return participants
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, {faction: string?, player: string, position: string, flag: string?}>
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	-- resolve the aliases in case they are used
	mapInput['t' .. opponentIndex .. 'p1race'] = Logic.emptyOr(
		mapInput['t' .. opponentIndex .. 'p1race'],
		mapInput['race' .. opponentIndex],
		mapInput['opponent' .. opponentIndex .. 'race']
	)

	local archonFaction = Faction.read(mapInput['t' .. opponentIndex .. 'p1race']) or players[1].extradata.faction
	local isArchon = MapFunctions.isArchon(mapInput, opponent, opponentIndex)

	local participants = {}

	Array.forEach(players, function(player, playerIndex)
		local faction = isArchon and archonFaction or
			Logic.emptyOr(Faction.read(mapInput['t' .. opponentIndex .. 'p' .. playerIndex .. 'race']), player.Faction)

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = Faction.read(faction or player.extradata.faction),
			player = player.name
		}
	end)

	return participants
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
		local parsedOpponentIndex = key:match('(%d+)_%d+')
		local opponetIndex = tonumber(parsedOpponentIndex) --[[@as integer]]
		playerCounts[opponetIndex] = (playerCounts[opponetIndex] or 0) + 1
		-- only relevant for 1v1 maps, hence irrelevant if we overwrite it for other map types over and over
		players[opponetIndex] = participant
	end

	local modeParts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 0 then
			return Opponent.literal
		elseif count == 2 and MapFunctions.isArchon(mapInput, opponents[opponentIndex], opponentIndex) then
			return 'Archon'
		elseif count == 2 and Logic.readBool(mapInput['opponent' .. opponentIndex .. 'duoSpecial']) then
			return '2S'
		elseif count == 4 and Logic.readBool(mapInput['opponent' .. opponentIndex .. 'quadSpecial']) then
			return '4S'
		end

		return count
	end)

	map.mode = table.concat(modeParts, 'v')

	if map.mode ~= '1v1' then return end

	map.extradata.opponent1 = opponents[1].name
	map.extradata.opponent2 = opponents[2].name

	if map.winner ~= 1 and map.winner ~= 2 then return end
	local loser = 3 - map.winner

	map.extradata.winnerfaction = players[map.winner].faction
	map.extradata.loserfaction = players[loser].faction
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return boolean
function MapFunctions.isArchon(mapInput, opponent, opponentIndex)
	return Logic.readBool(mapInput['opponent' .. opponentIndex .. 'archon']) or
		Logic.readBool(opponent.extradata.isarchon)
end

return StarcraftMatchGroupInput
