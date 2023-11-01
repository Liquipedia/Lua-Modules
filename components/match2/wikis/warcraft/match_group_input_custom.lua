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
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapsData = mw.loadData('Module:Maps/data')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Streams = Lua.import('Module:Links/Stream', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local CONVERT_STATUS_INPUT = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 20
local DEFAULT_BEST_OF = 99
local LINKS_KEYS = {'preview', 'preview2', 'interview', 'interview2', 'review', 'recap', 'lrthread'}
local MODE_MIXED = 'mixed'
local TBD = 'tbd'
local NEUTRAL_HERO_FACTION = 'neutral'

local CustomMatchGroupInput = {}

--- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in warcraft match2')

	Table.mergeInto(
		match,
		CustomMatchGroupInput._readDate(match)
	)
	match.patch = PatchAuto.retrieve{date = match.date}
	CustomMatchGroupInput._getTournamentVars(match)
	CustomMatchGroupInput._adjustData(match)
	CustomMatchGroupInput._updateFinished(match)
	match.stream = Streams.processStreams(match)
	CustomMatchGroupInput._getLinks(match)
	CustomMatchGroupInput._getExtraData(match)

	return match
end

---@param matchArgs table
---@return table
function CustomMatchGroupInput._readDate(matchArgs)
	local suggestedDate = Variables.varDefault('matchDate') or Variables.varDefault('Match_date')

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

	suggestedDate = suggestedDate or Variables.varDefaultMulti(
		'tournament_startdate',
		'tournament_enddate',
		'1970-01-01'
	)

	return {
		date = MatchGroupInput.getInexactDate(suggestedDate),
		dateexact = false,
	}
end

---@param match table
function CustomMatchGroupInput._updateFinished(match)
	match.finished = Logic.nilOr(Logic.readBoolOrNil(match.finished), Logic.isNotEmpty(match.winner))
	if match.finished then
		return
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	local currentUnixTime = os.time(os.date('!*t') --[[@as osdateparam]])
	local matchUnixTime = tonumber(mw.getContentLanguage():formatDate('U', match.date))
	local threshold = match.dateexact and 30800 or 86400
	match.finished = matchUnixTime + threshold < currentUnixTime
end

---@param match table
function CustomMatchGroupInput._getTournamentVars(match)
	match.cancelled = Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament', 'false'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	Variables.varDefine('headtohead', match.headtohead)
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.bestof = tonumber(Logic.emptyOr(match.bestof, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', match.bestof)

	MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
function CustomMatchGroupInput._getLinks(match)
	match.links = {}
	for _, linkKey in pairs(LINKS_KEYS) do
		match.links[linkKey] = match[linkKey]
	end
end

---@param match table
function CustomMatchGroupInput._getExtraData(match)
	match.extradata = {
		casters = MatchGroupInput.readCasters(match),
		headtohead = match.headtohead,
		ffa = 'false',
	}

	for prefix, mapVeto in Table.iter.pairsByPrefix(match, 'veto') do
		match.extradata[prefix] = (MapsData[mapVeto:lower()] or {}).name or mapVeto
		match.extradata[prefix .. 'by'] = match[prefix .. 'by']
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
	local walkover = match.walkover
	local numberofOpponents = 0
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
			numberofOpponents = numberofOpponents + 1
			--determine opponent scores, status and placement
			--determine MATCH winner, resulttype and walkover
			--the following ignores the possibility of > 2 opponents
			--as > 2 opponents is only possible in ffa
			if Logic.isNotEmpty(walkover) then
				if Logic.isNumeric(walkover) then
					local numericWalkover = tonumber(walkover)
					if numericWalkover == opponentIndex then
						match.winner = opponentIndex
						match.walkover = 'L'
						opponent.status = 'W'
					elseif numericWalkover == 0 then
						match.winner = 0
						match.walkover = 'L'
						opponent.status = 'L'
					else
						local score = string.upper(opponent.score or '')
						opponent.status = CONVERT_STATUS_INPUT[score] or 'L'
					end
				elseif Table.includes(ALLOWED_STATUSES, string.upper(walkover)) then
					if tonumber(match.winner or 0) == opponentIndex then
						opponent.status = 'W'
					else
						opponent.status = CONVERT_STATUS_INPUT[string.upper(walkover)] or 'L'
					end
				else
					local score = string.upper(opponent.score or '')
					opponent.status = CONVERT_STATUS_INPUT[score] or 'L'
					match.walkover = 'L'
				end
				opponent.score = -1
				match.finished = true
				match.resulttype = 'default'
			elseif CONVERT_STATUS_INPUT[string.upper(opponent.score or '')] then
				if string.upper(opponent.score) == 'W' then
					match.winner = opponentIndex
					match.resulttype = 'default'
					match.finished = true
					opponent.score = -1
					opponent.status = 'W'
				else
					match.resulttype = 'default'
					match.finished = true
					match.walkover = CONVERT_STATUS_INPUT[string.upper(opponent.score)]
					local score = string.upper(opponent.score)
					opponent.status = CONVERT_STATUS_INPUT[score]
					opponent.score = -1
				end
			else
				opponent.status = 'S'
				opponent.score = tonumber(opponent.score) or
					tonumber(opponent.sumscore) or -1
				if opponent.score > bestof / 2 then
					match.finished = Logic.emptyOr(match.finished, true)
					match.winner = tonumber(match.winner or '') or opponentIndex
				end
			end

			if Logic.readBool(match.cancelled) then
				match.finished = true
				if String.isEmpty(match.resulttype) and Logic.isEmpty(opponent.score) then
					match.resulttype = 'np'
					opponent.score = opponent.score or -1
				end
			end
		else
			break
		end
	end

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
	local teamName = opponent.name
	local playersData = Json.parseIfString(opponent.players) or {}

	local players = {}

	for playerIndex = 1, MAX_NUM_PLAYERS do
		local player = Json.parseIfString(Table.extract(match, 'opponent' .. opponentIndex .. '_p' .. playerIndex)) or {}

		player.name = Logic.emptyOr(player.name, playersData['p' .. playerIndex],
			Variables.varDefault(teamName .. '_p' .. playerIndex))

		player.name = player.name and mw.ext.TeamLiquidIntegration.resolve_redirect(player.name):gsub(' ', '_') or nil

		player.flag = Logic.emptyOr(player.flag, playersData['p' .. playerIndex .. 'flag'],
			Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag'))

		local faction = Faction.read(Logic.emptyOr(player.race, playersData['p' .. playerIndex .. 'race'],
			Variables.varDefault(teamName .. '_p' .. playerIndex .. 'race')))

		player.displayname = player.displayname or playersData['p' .. playerIndex .. 'dn']
			or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'dn')

		if Table.isNotEmpty(player) or faction then
			player.extradata = {faction = faction or Faction.defaultFaction}
			table.insert(players, player)
		end
	end

	opponent.match2players = players

	return opponent
end

---@param opponent table
---@return table
function CustomMatchGroupInput.ProcessLiteralOpponentInput(opponent)
	local race = opponent.race
	local flag = opponent.flag
	local name = opponent.name or opponent[1]
	local extradata = opponent.extradata

	local players = {}
	if String.isNotEmpty(race) or String.isNotEmpty(flag) then
		players[1] = {
			displayname = name,
			name = TBD:upper(),
			flag = Flags.CountryName(flag),
			extradata = {faction = Faction.read(race) or Faction.defaultFaction}
		}
		extradata.hasRaceOrFlag = true
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
				Variables.varDefault(name .. '_page'),
				name
			)):gsub(' ', '_')
		table.insert(links, link)

		table.insert(players, {
			displayname = name,
			name = link,
			flag = Flags.CountryName(Logic.emptyOr(
					opponent['p' .. playerIndex .. 'flag'],
					Variables.varDefault(name .. '_flag')
				)),
			extradata = {faction = Faction.read(Logic.emptyOr(
					opponent['p' .. playerIndex .. 'race'],
					Variables.varDefault(name .. '_race')
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
	map.map = (MapsData[(map.map or ''):lower()] or {}).name or map.map

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment or '',
		header = map.header or '',
	}

	-- inherit stuff from match data
	map = MatchGroupInput.getCommonTournamentVars(map, match)
	map.date = map.date or match.date
	map.patch = match.patch

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode + winnerfaction and loserfaction
	--(w/l race stuff only for 1v1 maps)
	CustomMatchGroupInput.ProcessPlayerMapData(map, match, 2)

	--adjust sumscore for winner opponent
	if (tonumber(map.winner) or 0) > 0 then
		match['opponent' .. map.winner].sumscore =
			match['opponent' .. map.winner].sumscore + 1
	end

	-- handle subgroup stuff if team match
	if match.isTeamMatch then
		map.subgroup = tonumber(map.subgroup)
		if map.subgroup then
			subGroupIndex = map.subgroup
		else
			subGroupIndex = subGroupIndex + 1
			map.subgroup = subGroupIndex
		end
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
			score = CONVERT_STATUS_INPUT[score] or score
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

	if hasManualScores then
		for scoreIndex, _ in Table.iter.spairs(indexedScores, CustomMatchGroupInput._placementSortFunction) do
			if not tonumber(map.winner) then
				map.winner = scoreIndex
			else
				break
			end
		end
	else
		local winnerInput = tonumber(map.winner)
		if Logic.isNotEmpty(map.walkover) then
			local walkoverInput = tonumber(map.walkover)
			if walkoverInput == 1 then
				map.winner = 1
			elseif walkoverInput == 2 then
				map.winner = 2
			elseif walkoverInput == 0 then
				map.winner = 0
			end
			map.walkover = Table.includes(ALLOWED_STATUSES, map.walkover) and map.walkover or 'L'
			map.scores = {-1, -1}
			map.resulttype = 'default'
		elseif map.winner == 'skip' then
			map.scores = {-1, -1}
			map.resulttype = 'np'
		elseif winnerInput == 1 then
			map.scores = {1, 0}
		elseif winnerInput == 2 then
			map.scores = {0, 1}
		elseif winnerInput == 0 or map.winner == 'draw' then
			map.scores = {0.5, 0.5}
			map.resulttype = 'draw'
		end
	end

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

	local opponentRaces, playerNameArray = CustomMatchGroupInput._fetchOpponentMapRacesAndNames(participants)
	if tonumber(map.winner) == 1 then
		map.extradata.winnerfaction = opponentRaces[1]
		map.extradata.loserfaction = opponentRaces[2]
	elseif tonumber(map.winner) == 2 then
		map.extradata.winnerfaction = opponentRaces[2]
		map.extradata.loserfaction = opponentRaces[1]
	end
	map.extradata.opponent1 = playerNameArray[1]
	map.extradata.opponent2 = playerNameArray[2]
end

---@param participants table<string, table>
---@return table<integer, string>
---@return table<integer, string>
function CustomMatchGroupInput._fetchOpponentMapRacesAndNames(participants)
	local opponentRaces, playerNameArray = {}, {}
	for participantKey, participantData in pairs(participants) do
		local opponentIndex = tonumber(string.sub(participantKey, 1, 1))
		-- opponentIndex can not be nil due to the format of the participants keys
		---@cast opponentIndex -nil
		opponentRaces[opponentIndex] = participantData.faction
		playerNameArray[opponentIndex] = participantData.player
	end

	return opponentRaces, playerNameArray
end

---@param players table[]
---@param map table
---@param opponentIndex integer
---@param participants table<string, table>
---@return table<string, table>
function CustomMatchGroupInput._processPartyPlayerMapData(players, map, opponentIndex, participants)
	local prefix = 't' .. opponentIndex .. 'p'
	map[prefix .. '1race'] = Logic.emptyOr(map[prefix .. '1race'], map['race' .. opponentIndex])
	map[prefix .. '1heroes'] = Logic.emptyOr(map[prefix .. '1heroes'], map['heroes' .. opponentIndex])

	for playerIndex, player in pairs(players) do
		local faction = Logic.emptyOr(map[prefix .. playerIndex .. 'race'], player.extradata.faction, Faction.defaultFaction)
		faction = Faction.read(faction)

		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = faction,
			player = player.name,
			heroes = CustomMatchGroupInput._readHeroes(
				map[prefix .. playerIndex .. 'heroes'],
				faction,
				player.name,
				Logic.readBool(map[prefix .. playerIndex .. 'heroesNoCheck'])
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
			local link = Logic.emptyOr(map[prefix .. 'link'], Variables.varDefault(playerInput .. '_page'), playerInput)
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(link):gsub(' ', '_')

			playerData[link] = {
				faction = Faction.read(map[prefix .. 'race']),
				position = playerIndex,
				heroes = map[prefix .. 'heroes'],
				heroesCheckDisabled = Logic.readBool(map[prefix .. 'heroesNoCheck']),
			}
		end
	end

	for playerIndex, player in pairs(players) do
		local currentPlayer = playerData[player.name]
		if currentPlayer then
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
			}
		end
	end

	for tbdIndex = 1, amountOfTbds do
		participants[opponentIndex .. '_' .. (#players + tbdIndex)] = {
			faction = Faction.defaultFaction,
			player = TBD:upper(),
		}
	end

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
			or faction == heroData.faction or heroData.faction == NEUTRAL_HERO_FACTION,
			'Invalid hero input "' .. hero .. '" for race "' .. Faction.toName(faction) .. '" of player "' .. playerName .. '"')

		return heroData.name
	end)
end

-- function to sort out winner/placements
---@param tbl table
---@param key1 string
---@param key2 string
---@return boolean
function CustomMatchGroupInput._placementSortFunction(tbl, key1, key2)
	local opponent1 = tbl[key1]
	local opponent2 = tbl[key2]
	local opponent1Norm = opponent1.status == 'S'
	local opponent2Norm = opponent2.status == 'S'
	if opponent1Norm then
		if opponent2Norm then
			return tonumber(opponent1.score) > tonumber(opponent2.score)
		else return true end
	else
		if opponent2Norm then return false
		elseif opponent1.status == 'W' then return true
		elseif Table.includes(DEFAULT_LOSS_STATUSES, opponent1.status) then return false
		elseif opponent2.status == 'W' then return false
		elseif Table.includes(DEFAULT_LOSS_STATUSES, opponent2.status) then return true
		else return true end
	end
end

return CustomMatchGroupInput
