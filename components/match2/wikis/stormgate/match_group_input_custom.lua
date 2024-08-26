---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local HeroData = mw.loadData('Module:HeroData')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')
local Streams = Lua.import('Module:Links/Stream')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local DEFAULT_WIN_STATUS = 'W'
local SCORE_STATUS = 'S'
local ALLOWED_STATUSES = Array.append(DEFAULT_LOSS_STATUSES, DEFAULT_WIN_STATUS)
local RESULT_TYPE_DEFAULT = 'default'
local RESULT_TYPE_NOT_PLAYED = 'np'
local MAX_NUM_OPPONENTS = 2
local DEFAULT_BEST_OF = 99
local MODE_MIXED = 'mixed'
local TBD = 'tbd'
local DEFAULT_HERO_FACTION = HeroData.default.faction
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

local CustomMatchGroupInput = {}

--- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in stormgate match2')

	Table.mergeInto(
		match,
		CustomMatchGroupInput._readDate(match)
	)
	CustomMatchGroupInput._getTournamentVars(match)
	CustomMatchGroupInput._adjustData(match)
	CustomMatchGroupInput._updateFinished(match)
	match.stream = Streams.processStreams(match)
	CustomMatchGroupInput._getExtraData(match)

	return match
end

---@param matchArgs table
---@return table
function CustomMatchGroupInput._readDate(matchArgs)
	local dateProps = MatchGroupInput.readDate(matchArgs.date, {
		'matchDate',
		'tournament_startdate',
		'tournament_enddate'
	})

	if dateProps.dateexact then
		Variables.varDefine('matchDate', dateProps.date)
	end

	return dateProps
end

---@param match table
function CustomMatchGroupInput._updateFinished(match)
	match.finished = Logic.nilOr(Logic.readBoolOrNil(match.finished), Logic.isNotEmpty(match.winner))
	if match.finished then
		return
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	local threshold = match.dateexact and 30800 or 86400
	match.finished = match.timestamp + threshold < NOW
end

---@param match table
function CustomMatchGroupInput._getTournamentVars(match)
	match.cancelled = Logic.emptyOr(match.cancelled, Variables.varDefault('tournament_cancelled', 'false'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.bestof = tonumber(Logic.emptyOr(match.bestof, Variables.varDefault('match_bestof')))
	Variables.varDefine('match_bestof', match.bestof)

	MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
function CustomMatchGroupInput._getExtraData(match)
	match.extradata = {
		casters = MatchGroupInput.readCasters(match),
		ffa = 'false',
	}

	for prefix, mapVeto in Table.iter.pairsByPrefix(match, 'veto') do
		match.extradata[prefix] = mapVeto and mw.ext.TeamLiquidIntegration.resolve_redirect(mapVeto) or nil
		match.extradata[prefix .. 'by'] = match[prefix .. 'by']
		match.extradata[prefix .. 'displayname'] = match[prefix .. 'displayName']
	end

	Table.mergeInto(match.extradata, Table.filterByKey(match, function(key, value)
		return key:match('subgroup%d+header') end))
end

---@param match table
function CustomMatchGroupInput._adjustData(match)
	--parse opponents + set base sumscores + set mode
	CustomMatchGroupInput._opponentInput(match)

	--main processing done here
	local subGroupIndex = 0
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		subGroupIndex = CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	end

	CustomMatchGroupInput._matchWinnerProcessing(match)
end

---@param match table
function CustomMatchGroupInput._matchWinnerProcessing(match)
	local bestof = match.bestof or DEFAULT_BEST_OF
	local numberofOpponents = 0

	Array.map(Array.range(1, MAX_NUM_OPPONENTS),function(opponentIndex)
		local opponent = match['opponent' .. opponentIndex]

		if Logic.isEmpty(opponent) then return end

		numberofOpponents = numberofOpponents + 1

		if Table.includes(ALLOWED_STATUSES, string.upper(opponent.score or '')) then
			opponent.status = string.upper(opponent.score)
			match.resulttype = RESULT_TYPE_DEFAULT
			match.finished = true
			opponent.score = -1

			if opponent.status == DEFAULT_WIN_STATUS then
				match.winner = opponentIndex
			else
				match.walkover = opponent.status
			end
		else
			opponent.status = SCORE_STATUS
			opponent.score = tonumber(opponent.score) or tonumber(opponent.sumscore) or -1
			if opponent.score > bestof / 2 then
				match.finished = Logic.emptyOr(match.finished, true)
				match.winner = tonumber(match.winner) or opponentIndex
			end
		end

		if Logic.readBool(match.cancelled) then
			match.finished = true
			if String.isEmpty(match.resulttype) and Logic.isEmpty(opponent.score) then
				match.resulttype = RESULT_TYPE_NOT_PLAYED
				opponent.score = opponent.score or -1
			end
		end

		-- to not break the loop
		return true
	end)

	CustomMatchGroupInput._determineWinnerIfMissing(match)

	for opponentIndex = 1, numberofOpponents do
		local opponent = match['opponent' .. opponentIndex]
		if match.winner == 'draw' or tonumber(match.winner) == 0 or
				(match.opponent1.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
			match.finished = true
			match.winner = 0
			match.resulttype = 'draw'
		end

		if tonumber(match.winner) == opponentIndex or
			match.resulttype == 'draw' then
			opponent.placement = 1
		elseif Logic.isNumeric(match.winner) then
			opponent.placement = 2
		end
	end
end

---@param match table
---@return table
function CustomMatchGroupInput._determineWinnerIfMissing(match)
	if Logic.readBool(match.finished) and Logic.isEmpty(match.winner) then
		local scores = Array.mapIndexes(function(opponentIndex)
			local opponent = match['opponent' .. opponentIndex]
			if not opponent then
				return nil
			end
			return match['opponent' .. opponentIndex].score or -1 end
		)
		local maxScore = math.max(unpack(scores) or 0)
		-- if we have a positive score and the match is finished we also have a winner
		if maxScore > 0 then
			local maxIndexFound = false
			for opponentIndex, score in pairs(scores) do
				if maxIndexFound and score == maxScore then
					match.winner = 0
					break
				elseif score == maxScore then
					maxIndexFound = true
					match.winner = opponentIndex
				end
			end
		end
	end

	return match
end

--OpponentInput functions

---@param match table
---@return table
function CustomMatchGroupInput._opponentInput(match)
	local opponentTypes = {}

	for opponentKey, opponent, opponentIndex in Table.iter.pairsByPrefix(match, 'opponent') do
		opponent = Json.parseIfString(opponent)

		--Convert byes to literals
		if Opponent.isBye(opponent) then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

		-- Opponent processing (first part)
		-- Sort out extradata
		opponent.extradata = {
			advantage = opponent.advantage,
			penalty = opponent.penalty,
			score2 = opponent.score2,
		}

		local partySize = Opponent.partySize(opponent.type)
		if partySize then
			opponent = CustomMatchGroupInput.processPartyOpponentInput(opponent, partySize)
		elseif opponent.type == Opponent.team then
			opponent = CustomMatchGroupInput.ProcessTeamOpponentInput(opponent, match.date)
			opponent = CustomMatchGroupInput._readPlayersOfTeam(match, opponentIndex, opponent)
		elseif opponent.type == Opponent.literal then
			opponent = CustomMatchGroupInput.ProcessLiteralOpponentInput(opponent)
		else
			error('Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
		end

		--set initial opponent sumscore
		opponent.sumscore = tonumber(opponent.extradata.advantage) or (-1 * (tonumber(opponent.extradata.penalty) or 0))

		table.insert(opponentTypes, opponent.type)

		match[opponentKey] = opponent
	end

	assert(#opponentTypes <= MAX_NUM_OPPONENTS, 'Too many opponents')

	match.mode = Array.all(opponentTypes, function(opponentType) return opponentType == opponentTypes[1] end)
		and opponentTypes[1] or MODE_MIXED

	match.isTeamMatch = Array.any(opponentTypes, function(opponentType) return opponentType == Opponent.team end)

	return match
end

---reads the players of a team from input and wiki variables
---@param match table
---@param opponentIndex integer
---@param opponent table
---@return table
function CustomMatchGroupInput._readPlayersOfTeam(match, opponentIndex, opponent)
	local players = {}

	local teamName = opponent.name

	local insertIntoPlayers = function(player)
		if type(player) ~= 'table' or Logic.isEmpty(player) or Logic.isEmpty(player.name) then
			return
		end

		player.name = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name):gsub(' ', '_')
		player.flag = Flags.CountryName(player.flag)
		player.displayname = Logic.emptyOr(player.displayname, player.displayName)
		player.extradata = {faction = Faction.read(player.faction)}

		players[player.name] = players[player.name] or {}
		Table.deepMergeInto(players[player.name], player)
	end

	local playerIndex = 1
	local varPrefix = teamName .. '_p' .. playerIndex
	local name = Variables.varDefault(varPrefix)
	while name do
		insertIntoPlayers{
			name = name,
			displayName = Variables.varDefault(varPrefix .. 'dn'),
			faction = Variables.varDefault(varPrefix .. 'faction'),
			flag = Variables.varDefault(varPrefix .. 'flag'),
		}
		playerIndex = playerIndex + 1
		varPrefix = teamName .. '_p' .. playerIndex
		name = Variables.varDefault(varPrefix)
	end

	--players from manual input as `opponnetX_pY`
	for _, player in Table.iter.pairsByPrefix(match, 'opponent' .. opponentIndex .. '_p') do
		insertIntoPlayers(Json.parseIfString(player))
	end

	opponent.match2players = Array.extractValues(players)
	--set default faction for unset factions
	Array.forEach(opponent.match2players, function(player)
		player.extradata.faction = player.extradata.faction or Faction.defaultFaction
	end)

	return opponent
end

---@param opponent table
---@return table
function CustomMatchGroupInput.ProcessLiteralOpponentInput(opponent)
	local faction = opponent.faction
	local flag = opponent.flag
	local name = opponent.name or opponent[1]
	local extradata = opponent.extradata

	local players = {}
	if String.isNotEmpty(faction) or String.isNotEmpty(flag) then
		players[1] = {
			displayname = name,
			name = TBD:upper(),
			flag = Flags.CountryName(flag),
			extradata = {faction = Faction.read(faction) or Faction.defaultFaction}
		}
		extradata.hasFactionOrFlag = true
	end

	return {
		type = opponent.type,
		name = name,
		score = opponent.score,
		extradata = extradata,
		match2players = players
	}
end

---@param opponent table
---@param partySize integer
---@return table
function CustomMatchGroupInput.processPartyOpponentInput(opponent, partySize)
	local players = {}
	local links = {}

	for playerIndex = 1, partySize do
		local name = Logic.emptyOr(opponent['p' .. playerIndex], opponent[playerIndex]) or ''
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
				opponent['p' .. playerIndex .. 'link'],
				Variables.varDefault(name .. '_page')
			) or name):gsub(' ', '_')
		table.insert(links, link)

		table.insert(players, {
			displayname = name,
			name = link,
			flag = Flags.CountryName(Logic.emptyOr(
					opponent['p' .. playerIndex .. 'flag'],
					Variables.varDefault(name .. '_flag')
				)),
			extradata = {faction = Faction.read(Logic.emptyOr(
					opponent['p' .. playerIndex .. 'faction'],
					Variables.varDefault(name .. '_faction')
				)) or Faction.defaultFaction}
		})
	end

	table.sort(links)

	return {
		type = opponent.type,
		name = table.concat(links, ' / '),
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param opponent table
---@param date string
---@return table
function CustomMatchGroupInput.ProcessTeamOpponentInput(opponent, date)
	local template = string.lower(Logic.emptyOr(opponent.template, opponent[1], '')--[[@as string]]):gsub('_', ' ')

	if String.isEmpty(template) or template == 'noteam' then
		opponent = Table.merge(opponent, Opponent.blank(Opponent.team))
		opponent.name = Opponent.toName(opponent)
		return opponent
	end

	assert(mw.ext.TeamTemplate.teamexists(template), 'Missing team template "' .. template .. '"')

	local templateData = mw.ext.TeamTemplate.raw(template, date)

	opponent.icon = templateData.image
	opponent.icondark = Logic.emptyOr(templateData.imagedark, templateData.image)
	opponent.name = templateData.page:gsub(' ', '_')
	opponent.template = templateData.templatename or template

	return opponent
end

--MapInput functions

---@param match table
---@param mapIndex integer
---@param subGroupIndex integer
---@return integer
function CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])
	map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		header = map.header,
	}

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode + winnerfaction and loserfaction
	--(w/l faction stuff only for 1v1 maps)
	CustomMatchGroupInput.ProcessPlayerMapData(map, match, 2)

	--adjust sumscore for winner opponent
	if (tonumber(map.winner) or 0) > 0 then
		match['opponent' .. map.winner].sumscore =
			match['opponent' .. map.winner].sumscore + 1
	end

	-- handle subgroup stuff if team match
	if match.isTeamMatch then
		map.subgroup = tonumber(map.subgroup) or (subGroupIndex + 1)
		subGroupIndex = map.subgroup
	end

	match['map' .. mapIndex] = map

	return subGroupIndex
end

---@param map table
---@return table
function CustomMatchGroupInput._mapWinnerProcessing(map)
	map.scores = {}
	local hasManualScores = false
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		local obj = {}
		if Logic.isNotEmpty(score) then
			hasManualScores = true
			score = score
			if Logic.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end

	local winner = tonumber(map.winner)
	if Logic.isNotEmpty(map.walkover) then
		local walkoverInput = tonumber(map.walkover)
		if walkoverInput == 1 or walkoverInput == 2 or walkoverInput == 0 then
			winner = walkoverInput
		end
		map.walkover = Table.includes(ALLOWED_STATUSES, map.walkover) and map.walkover or 'L'
		map.scores = {-1, -1}
		map.resulttype = 'default'
		map.winner = winner

		return map
	end

	if hasManualScores then
		map.winner = winner or CustomMatchGroupInput._getWinner(indexedScores)

		return map
	end

	if map.winner == 'skip' then
		map.scores = {-1, -1}
		map.resulttype = RESULT_TYPE_NOT_PLAYED
	elseif winner == 1 then
		map.scores = {1, 0}
	elseif winner == 2 then
		map.scores = {0, 1}
	elseif winner == 0 or map.winner == 'draw' then
		map.scores = {0.5, 0.5}
		map.resulttype = 'draw'
	end

	map.winner = winner

	return map
end

---@param map table
---@param match table
---@param numberOfOpponents integer
function CustomMatchGroupInput.ProcessPlayerMapData(map, match, numberOfOpponents)
	local participants = {}
	local modeParts = {}
	for opponentIndex = 1, numberOfOpponents do
		local opponent = match['opponent' .. opponentIndex]
		local partySize = Opponent.partySize(opponent.type)
		local players = opponent.match2players
		if partySize then
			table.insert(modeParts, partySize)
			CustomMatchGroupInput._processPartyPlayerMapData(players, map, opponentIndex, participants)
		elseif opponent.type == Opponent.team then
			table.insert(modeParts, CustomMatchGroupInput._processTeamPlayerMapData(players, map, opponentIndex, participants))
		elseif opponent.type == Opponent.literal then
			table.insert(modeParts, 'literal')
		end
	end

	map.mode = table.concat(modeParts, 'v')
	map.participants = participants

	if numberOfOpponents ~= MAX_NUM_OPPONENTS or map.mode ~= '1v1' then
		return
	end

	local opponentFactions, playerNameArray, heroesData
		= CustomMatchGroupInput._fetchOpponentMapParticipantData(participants)
	map.extradata = Table.merge(map.extradata, heroesData)
	if tonumber(map.winner) == 1 then
		map.extradata.winnerfaction = opponentFactions[1]
		map.extradata.loserfaction = opponentFactions[2]
	elseif tonumber(map.winner) == 2 then
		map.extradata.winnerfaction = opponentFactions[2]
		map.extradata.loserfaction = opponentFactions[1]
	end
	map.extradata.opponent1 = playerNameArray[1]
	map.extradata.opponent2 = playerNameArray[2]
end

---@param participants table<string, table>
---@return table<integer, string>
---@return table<integer, string>
---@return table<string, string>
function CustomMatchGroupInput._fetchOpponentMapParticipantData(participants)
	local opponentFactions, playerNameArray, heroesData = {}, {}, {}
	for participantKey, participantData in pairs(participants) do
		local opponentIndex = tonumber(string.sub(participantKey, 1, 1))
		-- opponentIndex can not be nil due to the format of the participants keys
		---@cast opponentIndex -nil
		opponentFactions[opponentIndex] = participantData.faction
		playerNameArray[opponentIndex] = participantData.player
		Array.forEach(participantData.heroes or {}, function(hero, heroIndex)
			heroesData['opponent' .. opponentIndex .. 'hero' .. heroIndex] = hero
		end)
	end

	return opponentFactions, playerNameArray, heroesData
end

---@param players table[]
---@param map table
---@param opponentIndex integer
---@param participants table<string, table>
---@return table<string, table>
function CustomMatchGroupInput._processPartyPlayerMapData(players, map, opponentIndex, participants)
	local prefix = 't' .. opponentIndex .. 'p'

	for playerIndex, player in pairs(players) do
		local faction = Logic.emptyOr(
			map[prefix .. playerIndex .. 'faction'],
			player.extradata.faction,
			Faction.defaultFaction
		)
		faction = Faction.read(faction)

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = faction,
			player = player.name,
			heroes = CustomMatchGroupInput._readHeroes(
				map[prefix .. playerIndex .. 'heroes'],
				faction,
				player.name,
				Logic.readBool(map[prefix .. playerIndex .. 'noheroescheck'])
			),
		}
	end

	return participants
end

---@param players table[]
---@param map table
---@param opponentIndex integer
---@param participants table<string, table>
---@return integer
function CustomMatchGroupInput._processTeamPlayerMapData(players, map, opponentIndex, participants)
	local amountOfTbds = 0
	local playerData = {}

	local numberOfPlayers = 0
	for prefix, playerInput, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
		numberOfPlayers = numberOfPlayers + 1
		if playerInput:lower() == TBD then
			amountOfTbds = amountOfTbds + 1
		else
			local link = Logic.emptyOr(map[prefix .. 'link'], Variables.varDefault(playerInput .. '_page')) or playerInput
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(link):gsub(' ', '_')

			playerData[link] = {
				faction = Faction.read(map[prefix .. 'faction']),
				position = playerIndex,
				heroes = map[prefix .. 'heroes'],
				heroesCheckDisabled = Logic.readBool(map[prefix .. 'noheroescheck']),
				playedRandom = Logic.readBool(map[prefix .. 'random']),
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
			heroes = CustomMatchGroupInput._readHeroes(
				currentPlayer.heroes,
				faction,
				player.name,
				currentPlayer.heroesCheckDisabled
			),
			random = currentPlayer.playedRandom,
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
		numberOfPlayers = numberOfPlayers + 1
	end)

	Array.forEach(Array.range(1, amountOfTbds), function(tbdIndex)
		participants[opponentIndex .. '_' .. (#players + tbdIndex)] = {
			faction = Faction.defaultFaction,
			player = TBD:upper(),
		}
	end)

	map.participants = participants

	return numberOfPlayers
end

---@param heroesInput string?
---@param faction string?
---@param playerName string
---@param ignoreFactionHeroCheck boolean
---@return string[]?
function CustomMatchGroupInput._readHeroes(heroesInput, faction, playerName, ignoreFactionHeroCheck)
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
			or faction == heroData.faction or heroData.faction == DEFAULT_HERO_FACTION,
			'Invalid hero input "' .. hero .. '" for faction "'
				.. Faction.toName(faction) .. '" of player "' .. playerName .. '"')

		return heroData.name
	end)
end

---@param indexedScores table
---@return integer?
function CustomMatchGroupInput._getWinner(indexedScores)
	table.sort(indexedScores, CustomMatchGroupInput._mapWinnerSortFunction)

	return indexedScores[1].index
end

---@param opponent1 table
---@param opponent2 table
---@return boolean
function CustomMatchGroupInput._mapWinnerSortFunction(opponent1, opponent2)
	local opponent1Norm = opponent1.status == SCORE_STATUS
	local opponent2Norm = opponent2.status == SCORE_STATUS

	if opponent1Norm and opponent2Norm then
		return tonumber(opponent1.score) > tonumber(opponent2.score)
	elseif opponent1Norm then return true
	elseif opponent2Norm then return false
	elseif opponent1.status == DEFAULT_WIN_STATUS then return true
	elseif Table.includes(ALLOWED_STATUSES, opponent1.status) then return false
	elseif opponent2.status == DEFAULT_WIN_STATUS then return false
	elseif Table.includes(ALLOWED_STATUSES, opponent2.status) then return true
	else return true
	end
end

return CustomMatchGroupInput
