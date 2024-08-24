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
local HeroData = mw.loadData('Module:HeroData')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapsData = mw.loadData('Module:Maps/data')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local Streams = Lua.import('Module:Links/Stream')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	pagifyPlayerNames = true,
}
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
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in warcraft match2')

	Table.mergeInto(match, MatchFunctions.readDate(match))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	match.patch = PatchAuto.retrieve{date = match.date}

	Array.forEach(opponents, function(opponent)
		opponent.extradata = opponent.extradata or {}
		Table.mergeInto(opponent.extradata, MatchFunctions.getOpponentExtradata(opponent))
		-- make sure match2players is not nil to avoid indexing nil
		opponent.match2players = opponent.match2players or {}
		Array.forEach(opponent.match2players, function(player)
			player.extradata = player.extradata or {}
			player.extradata.faction = MatchFunctions.getPlayerFaction(player)
		end)
	end)

	local games = MatchFunctions.extractMaps(match, opponents)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games, opponents)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInput.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
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

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchFunctions.readDate(matchArgs)
	local suggestedDate = Variables.varDefault('matchDate')

	local tournamentStartTime = Variables.varDefault('tournament_starttimeraw')

	if matchArgs.date or (not suggestedDate and tournamentStartTime) then
		local dateProps = MatchGroupInput.readDate(matchArgs.date or tournamentStartTime)
		dateProps.dateexact = Logic.nilOr(
			Logic.readBoolOrNil(matchArgs.dateexact),
			matchArgs.date and dateProps.dateexact or false
		)
		Variables.varDefine('matchDate', dateProps.date)
		return dateProps
	end

	return MatchGroupInput.readDate(nil, {
		'matchDate',
		'tournament_startdate',
		'tournament_enddate',
	})
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	local subGroup = 0
	for mapKey, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map
		map, subGroup = MapFunctions.readMap(mapInput, subGroup, #opponents)

		map.participants = MapFunctions.getParticipants(mapInput, opponents)

		map.mode = MapFunctions.getMode(mapInput, map.participants, opponents)

		Table.mergeInto(map.extradata, MapFunctions.getAdditionalExtraData(map, map.participants))

		map.vod = Logic.emptyOr(mapInput.vod, match['vodgame' .. mapIndex])

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param maps table[]
---@param opponents table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, opponents)
	return function(opponentIndex)
		local calculatedScore = MatchGroupInput.computeMatchScoreFromMapWinners(maps, opponentIndex)
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
	return player.extradata.faction or Faction.defaultFaction
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
---@return table
function MatchFunctions.getLinks(match)
	return {
		preview = match.preview,
		preview2 = match.preview2,
		interview = match.interview,
		interview2 = match.interview2,
		review = match.review,
		recap = match.recap,
	}
end

---@param match table
---@param numberOfGames integer
---@return table
function MatchFunctions.getExtraData(match, numberOfGames)
	local extradata = {
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
		ffa = 'false',
	}

	for prefix, mapVeto in Table.iter.pairsByPrefix(match, 'veto') do
		match.extradata[prefix] = (MapsData[mapVeto:lower()] or {}).name or mapVeto
		match.extradata[prefix .. 'by'] = match[prefix .. 'by']
	end

	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match('subgroup%d+header') end))

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

---@param mapInput table
---@param subGroup integer
---@param opponentCount integer
---@return table
---@return integer
function MapFunctions.readMap(mapInput, subGroup, opponentCount)
	subGroup = tonumber(mapInput.subgroup) or (subGroup + 1)

	local mapName = (MapsData[(mapInput.map or ''):lower()] or {}).name or mapInput.map

	local map = {
		map = mapName,
		patch = Variables.varDefault('tournament_patch', ''),
		subgroup = subGroup,
		extradata = {
			comment = mapInput.comment,
			header = mapInput.header,
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

	if Logic.isNotEmpty(mapInput.walkover) then
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
---@return table<string, WarcraftParticipant>
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
---@return table<string, WarcraftParticipant>
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	---@type {input:string,faction:string?,link:string?,heroes:string?,heroesCheckDisabled:boolean,playedRandom:boolean}[]
	local participantsList = Array.mapIndexes(function(playerIndex)
		local prefix = 't' .. opponentIndex .. 'p' .. playerIndex

		if Logic.isEmpty(mapInput[prefix]) then return end

		return {
			input = mapInput[prefix],
			link = Logic.nilIfEmpty(mapInput[prefix .. 'link']),
			faction = Faction.read(mapInput[prefix .. 'race']),
			heroes = mapInput[prefix .. 'heroes'],
			heroesCheckDisabled = Logic.readBool(mapInput[prefix .. 'heroesNoCheck']),
			playedRandom = Logic.readBool(mapInput[prefix .. 'random']),
		}
	end)

	local participants = {}

	Array.forEach(participantsList, function(participantInput, position)
		local nameInput = participantInput.input

		local isTBD = nameInput:upper() == TBD

		local link = participantInput.link or Variables.varDefault(nameInput .. '_page') or nameInput
		link = Page.pageifyLink(link) --[[@as string -- can't be nil as input isn't nil]]

		local playerIndex = MapFunctions.getPlayerIndex(players, link, nameInput)

		-- in case we have a TBD or a player not known in match2players inster a new player in match2players
		if isTBD or playerIndex == 0 then
			table.insert(players, {
				name = isTBD and TBD or link,
				displayname = isTBD and TBD or nameInput,
				extradata = {faction = participantInput.faction or Faction.defaultFaction},
			})
			playerIndex = #players
		end

		local player = players[playerIndex]
		local faction = participantInput.faction or player.extradata.faction

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = faction,
			player = link,
			position = position,
			flag = Flags.CountryName(player.flag),
			random = participantInput.playedRandom,
			heroes = MapFunctions.readHeroes(
				participantInput.heroes,
				faction,
				link,
				participantInput.heroesCheckDisabled
			),
		}
	end)

	return participants
end

---@param players {name: string, displayname: string}
---@param name string
---@param displayName string
---@return integer
function MapFunctions.getPlayerIndex(players, name, displayName)
	local playerIndex =  Array.indexOf(players, function(player) return player.name == name end)

	if playerIndex ~= 0 then
		return playerIndex
	end

	return Array.indexOf(players, function(player) return player.displayname == displayName end)
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, WarcraftParticipant>
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	-- resolve the aliases in case they are used
	local prefix = 't' .. opponentIndex .. 'p'
	mapInput[prefix .. '1race'] = Logic.emptyOr(mapInput[prefix .. '1race'], mapInput['race' .. opponentIndex])
	mapInput[prefix .. '1heroes'] = Logic.emptyOr(mapInput[prefix .. '1heroes'], mapInput['heroes' .. opponentIndex])

	local participants = {}

	Array.forEach(players, function(player, playerIndex)
		local faction = Faction.read(mapInput['t' .. opponentIndex .. 'p' .. playerIndex .. 'race'])
			or player.extradata.faction

		participants[opponentIndex .. '_' .. playerIndex] = {
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

	return participants
end

---@param mapInput table # the input data
---@param participants table<string, WarcraftParticipant>
---@param opponents table[]
---@return string
function MapFunctions.getMode(mapInput, participants, opponents)
	-- assume we have a min of 2 opponents in a game
	local playerCounts = {0, 0}
	for key in pairs(participants) do
		local parsedOpponentIndex = key:match('(%d+)_%d+')
		local opponetIndex = tonumber(parsedOpponentIndex) --[[@as integer]]
		playerCounts[opponetIndex] = (playerCounts[opponetIndex] or 0) + 1
	end

	local modeParts = Array.map(playerCounts, function(count, opponentIndex)
		if count == 0 then
			return Opponent.literal
		end

		return count
	end)

	return table.concat(modeParts, 'v')
end

---@param map table
---@param participants table<string, WarcraftParticipant>
---@return table
function MapFunctions.getAdditionalExtraData(map, participants)
	if map.mode ~= '1v1' then return {} end

	local extradata = MapFunctions.getHeroesExtradata(participants)

	local players = {}
	for _, player in Table.iter.spairs(participants) do
		table.insert(players, player)
	end

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

--- additionally store heroes in extradata so we can condition on them
---@param participants table<string, WarcraftParticipant>
---@return table
function MapFunctions.getHeroesExtradata(participants)
	local extradata = {}
	for participantKey, participant in Table.iter.spairs(participants) do
		local opponentIndex = string.match(participantKey, '^(%d+)_')
		Array.forEach(participant.heroes or {}, function(hero, heroIndex)
			extradata['opponent' .. opponentIndex .. 'hero' .. heroIndex] = hero
		end)
	end

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
		local heroData = HeroData[hero:lower()]
		assert(heroData, 'Invalid hero input "' .. hero .. '"')

		local isCoreFaction = Table.includes(Faction.coreFactions, faction)
		assert(ignoreFactionHeroCheck or not isCoreFaction
			or faction == heroData.faction or heroData.faction == NEUTRAL_HERO_FACTION,
			'Invalid hero input "' .. hero .. '" for race "' .. Faction.toName(faction) .. '" of player "' .. playerName .. '"')

		return heroData.name
	end)
end

return CustomMatchGroupInput
