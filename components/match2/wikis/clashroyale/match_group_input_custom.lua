---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local CardNames = mw.loadData('Module:CardNames')
local Variables = require('Module:Variables')

local config = Lua.loadDataIfExists('Module:Match/Config') or {}
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local Streams = Lua.import('Module:Links/Stream', {requireDevIfEnabled = true})

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20
local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local CONVERT_STATUS_INPUT = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS_PER_MAP = 2
local DEFAULT_BEST_OF = 99
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'
local TBD = 'tbd'
local TBD_PLAYERS = {TBD, 'tba'}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match)
	Table.mergeInto(
		match,
		CustomMatchGroupInput._readDate(match)
	)
	match = CustomMatchGroupInput._getExtraData(match)
	match = CustomMatchGroupInput._getTournamentVars(match)
	match = CustomMatchGroupInput._checkFinished(match)
	match = CustomMatchGroupInput._adjustData(match)
	match = CustomMatchGroupInput._getVodStuff(match)
	match = CustomMatchGroupInput._getLinks(match)

	return match
end

function CustomMatchGroupInput._readDate(matchArgs)
	if matchArgs.date then
		return MatchGroupInput.readDate(matchArgs.date)
	else
		return {
			date = EPOCH_TIME_EXTENDED,
			dateexact = false,
			timestamp = DateExt.epochZero,
		}
	end
end

function CustomMatchGroupInput._checkFinished(match)
	if Logic.readBoolOrNil(match.finished) == false then
		match.finished = false
	elseif Logic.readBool(match.finished) then
		match.finished = true
	elseif Logic.isNotEmpty(match.winner) then
		match.finished = true
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	if match.finished ~= true then
		local currentUnixTime = os.time(os.date('!*t'))
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < currentUnixTime then
			match.finished = true
		end
	end

	return match
end

function CustomMatchGroupInput._getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'solo'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function CustomMatchGroupInput._getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)

	return match
end

function CustomMatchGroupInput._getLinks(match)
	match.links = {
		preview = match.preview,
		preview2 = match.preview2,
		interview = match.interview,
		interview2 = match.interview2,
		review = match.review,
		recap = match.recap,
		lrthread = match.lrthread,
	}
	return match
end

function CustomMatchGroupInput._getExtraData(match)
	local extradata = {
		casters = match.casters,
	}

	for subGroupIndex = 1, MAX_NUM_MAPS do
		extradata['subgroup' .. subGroupIndex .. 'header']
			= CustomMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
		extradata['subgroup' .. subGroupIndex .. 'iskoth']
			= Logic.readBool(match['subgroup' .. subGroupIndex .. 'iskoth'])
	end

	match.extradata = extradata

	return match
end

function CustomMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	local header = match['subgroup' .. subGroupIndex .. 'header']

	return String.isNotEmpty(header) and header or nil
end

function CustomMatchGroupInput._adjustData(match)
	--parse opponents + set base sumscores
	match = CustomMatchGroupInput._opponentInput(match)

	--main processing done here
	local subGroupIndex = 0
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		match, subGroupIndex = CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	end

	match = CustomMatchGroupInput._matchWinnerProcessing(match)

	if match.hasTeamOpponent then
		match.extradata.hasteamopponent = true
		match = CustomMatchGroupInput._subMatchStructure(match)
	end

	if Logic.isNumeric(match.winner) then
		match.finished = true
	end

	return match
end

--[[

Misc. MatchInput functions
--> Winner, Walkover, Placement, Resulttype, Status
--> Sub-Match Structure

]]--
function CustomMatchGroupInput._matchWinnerProcessing(match)
	local bestof = tonumber(match.bestof) or Variables.varDefault('bestof', DEFAULT_BEST_OF)
	Variables.varDefine('bestof', bestof)

	local walkover = match.walkover or ''

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
			--determine opponent scores, status and placement
			--determine MATCH winner, resulttype and walkover
			if String.isNotEmpty(walkover) then
				if Logic.isNumeric(walkover) then
					walkover = tonumber(walkover)
					if walkover == opponentIndex then
						match.winner = opponentIndex
						match.walkover = 'L'
						opponent.status = 'W'
					elseif walkover == 0 then
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
				if String.isEmpty(match.resulttype) and String.isEmpty(opponent.score) then
					match.resulttype = 'np'
					opponent.score = opponent.score or -1
				end
			end
		else
			break
		end
	end

	CustomMatchGroupInput._determineWinnerIfMissing(match)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if match.winner == 'draw' or tonumber(match.winner) == 0 or
				(match.opponent1.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
			match.finished = true
			match.winner = 0
			match.resulttype = 'draw'
		end
		if tonumber(match.winner) == opponentIndex or match.resulttype == 'draw' then
			opponent.placement = 1
		elseif Logic.isNumeric(match.winner) then
			opponent.placement = 2
		end
	end

	return match
end

function CustomMatchGroupInput._determineWinnerIfMissing(match)
	if Logic.readBool(match.finished) and not match.winner then
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

function CustomMatchGroupInput._subMatchStructure(match)
	local subMatches = {}

	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		local subGroupIndex = map.subgroup
		if not subMatches[subGroupIndex] then
			subMatches[subGroupIndex] = {scores = {0, 0}}
		end

		local winner = tonumber(map.winner)
		if winner and subMatches[subGroupIndex].scores[winner] then
			subMatches[subGroupIndex].scores[winner] = subMatches[subGroupIndex].scores[winner] + 1
		end
	end

	for subMatchIndex, subMatch in ipairs(subMatches) do
		-- get winner if the submatch is finished
		-- submatch is finished if the next submatch has a score or if the complete match is finished
		local nextSubMatch = subMatches[subMatchIndex + 1]
		if Logic.readBool(match.finished) or (nextSubMatch and nextSubMatch.scores[1] + nextSubMatch.scores[2] > 0) then
			if subMatch.scores[1] > subMatch.scores[2] then
				subMatch.winner = 1
			elseif subMatch.scores[2] > subMatch.scores[1] then
				subMatch.winner = 2
			end
		end
	end

	match.extradata.submatches = subMatches

	return match
end

--[[

OpponentInput functions

]]--
function CustomMatchGroupInput._opponentInput(match)
	local opponentIndex = 1
	local opponent = match['opponent' .. opponentIndex]

	while opponentIndex <= MAX_NUM_OPPONENTS and Logic.isNotEmpty(opponent) do
		opponent = Json.parseIfString(opponent) or Opponent.blank()

		-- Convert byes to literals
		if
			string.lower(opponent.template or '') == 'bye'
			or string.lower(opponent.name or '') == 'bye'
		then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

		--process input
		if opponent.type == Opponent.team or opponent.type == Opponent.solo or
			opponent.type == Opponent.duo or opponent.type == Opponent.literal then

			opponent = CustomMatchGroupInput.processOpponent(opponent, match.timestamp)
		else
			error('Unsupported Opponent Type')
		end

		-- Retrieve icon for team
		if opponent.type == Opponent.team then
			opponent.icon, opponent.icondark = CustomMatchGroupInput.getIcon(opponent.template)
			match.hasTeamOpponent = true
		end

		--set initial opponent sumscore
		opponent.sumscore = 0

		match['opponent' .. opponentIndex] = opponent

		opponentIndex = opponentIndex + 1
		opponent = match['opponent' .. opponentIndex]
	end

	return match
end

function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	local teamTemplateDate = timestamp
	-- If date is epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == DateExt.epochZero then
		teamTemplateDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			EPOCH_TIME_EXTENDED
		)
	end

	Opponent.resolve(opponent, teamTemplateDate)

	MatchGroupInput.mergeRecordWithOpponent(record, opponent)

	if record.type == Opponent.team then
		record.match2players = CustomMatchGroupInput._readTeamPlayers(record, record.players)
	end

	return record
end

function CustomMatchGroupInput._readTeamPlayers(opponent, playerData)
	local players = CustomMatchGroupInput._getManuallyEnteredPlayers(playerData)
	opponent.players = nil

	if Table.isEmpty(players) then
		players = CustomMatchGroupInput._getPlayersFromVariables(opponent.name)
	end

	return players
end

function CustomMatchGroupInput._getManuallyEnteredPlayers(playerData)
	local players = {}
	playerData = Json.parseIfString(playerData) or {}

	for prefix, displayName in Table.iter.pairsByPrefix(playerData, 'p') do
		local name = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			playerData[prefix .. 'link'],
			displayName
		))

		table.insert(players, {
			name = name,
			displayname = displayName,
			flag = Flags.CountryName(playerData[prefix .. 'flag']),
		})
	end

	return players
end

function CustomMatchGroupInput._getPlayersFromVariables(teamName)
	local players = {}

	local playerIndex = 1
	local prefix = teamName .. '_p' .. playerIndex
	local playerName = Variables.varDefault(prefix)
	while String.isNotEmpty(playerName) do
		table.insert(players, {
			name = playerName,
			displayname = Variables.varDefault(prefix .. 'dn'),
			flag = Flags.CountryName(Variables.varDefault(prefix .. 'flag')),
		})
	end

	return players
end

--[[

MapInput functions

]]--
function CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex]) or {}

	if Table.isEmpty(map) then
		match['map' .. mapIndex] = nil
		return match, subGroupIndex
	end

	-- CR has no map names, use generic one instead
	map.map = 'Set ' .. mapIndex

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		header = map.header,
	}

	-- inherit stuff from match data
	map.type = Logic.emptyOr(map.type, match.type)
	map.liquipediatier = match.liquipediatier
	map.liquipediatiertype = match.liquipediatiertype
	map.game = Logic.emptyOr(map.game, match.game)
	map.date = Logic.emptyOr(map.date, match.date)

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode
	map = CustomMatchGroupInput._processPlayerMapData(map, match)

	-- set sumscore to 0 if it isn't a number
	if String.isEmpty(match.opponent1.sumscore) then
		match.opponent1.sumscore = 0
	end
	if String.isEmpty(match.opponent2.sumscore) then
		match.opponent2.sumscore = 0
	end

	--adjust sumscore for winner opponent
	if (tonumber(map.winner) or 0) > 0 then
		match['opponent' .. map.winner].sumscore =
			match['opponent' .. map.winner].sumscore + 1
	end

	-- handle subgroup stuff if team match
	if match.hasTeamOpponent then
		map.subgroup = tonumber(map.subgroup)
		if map.subgroup then
			subGroupIndex = map.subgroup
		else
			subGroupIndex = subGroupIndex + 1
			map.subgroup = subGroupIndex
		end
	end

	match['map' .. mapIndex] = map

	return match, subGroupIndex
end

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
			if not tonumber(map.winner or '') then
				map.winner = scoreIndex
			else
				break
			end
		end
	else
		local winnerInput = tonumber(map.winner)
		if String.isNotEmpty(map.walkover) then
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
			map.scores = {0, 0}
			map.scores = {-1, -1}
			map.resulttype = 'np'
		elseif winnerInput == 1 then
			map.scores = {1, 0}
		elseif winnerInput == 2 then
			map.scores = {0, 1}
		end
	end

	return map
end

function CustomMatchGroupInput._processPlayerMapData(map, match)
	local participants = {}
	local submatchOpponentPlayerNumbers = {}

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]

		if opponent.type == Opponent.team then
			local playerNumber = CustomMatchGroupInput._processTeamPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)

			table.insert(submatchOpponentPlayerNumbers, playerNumber)
		elseif opponent.type == Opponent.literal then
			table.insert(submatchOpponentPlayerNumbers, opponent.type)
		else
			table.insert(submatchOpponentPlayerNumbers, #opponent.match2players)

			CustomMatchGroupInput._processDefaultPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)
		end
	end

	map.mode = table.concat(submatchOpponentPlayerNumbers, 'v')
	map.participants = participants

	return map
end

function CustomMatchGroupInput._processDefaultPlayerMapData(players, opponentIndex, map, participants)
	for playerIndex = 1, #players do
		participants[opponentIndex .. '_' .. playerIndex] = {
			played = true,
			cards = CustomMatchGroupInput._readCards(map['t' .. opponentIndex .. 'p' .. playerIndex .. 'c']),
		}
	end
end

function CustomMatchGroupInput._processTeamPlayerMapData(players, opponentIndex, map, participants)
	local tbdIndex = 0
	local appendIndex = #players + 1

	local playerIndex = 1
	local playerKey = 't' .. opponentIndex .. 'p' .. playerIndex
	while playerIndex < MAX_NUM_PLAYERS_PER_MAP and (String.isNotEmpty(map[playerKey]) or
		String.isNotEmpty(map[playerKey .. 'link']) or String.isNotEmpty(map[playerKey .. 'c'])) do

		local player = map[playerKey .. 'link'] or map[playerKey]
		if String.isEmpty(player) or Table.includes(TBD_PLAYERS, player:lower()) then
			tbdIndex = tbdIndex + 1
			player = TBD .. tbdIndex
		else
			-- allows fetching the link of the player from preset wiki vars
			player = mw.ext.TeamLiquidIntegration.resolve_redirect(
				map[playerKey .. 'link'] or Variables.varDefault(map[playerKey] .. '_page') or map[playerKey] or 'tbd'
			)
		end

		local playerData = {
			played = true,
			cards = CustomMatchGroupInput._readCards(map[playerKey .. 'c']),
		}

		local match2playerIndex = CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, player)

		-- if we have the player not present in match2player add basic data here
		if not match2playerIndex then
			match2playerIndex = appendIndex
			playerData = Table.merge(playerData, {name = player, displayname = map[playerKey] or player})

			appendIndex = appendIndex + 1
		end

		participants[opponentIndex .. '_' .. match2playerIndex] =  playerData

		playerIndex = playerIndex + 1
		playerKey = 't' .. opponentIndex .. 'p' .. playerIndex
	end

	return playerIndex - 1
end

function CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, player)
	for match2playerIndex, match2player in pairs(players) do
		if match2player and match2player.name == player then
			return match2playerIndex
		end
	end
end

function CustomMatchGroupInput._readCards(input)
	local cards = Json.parseIfString(input) or {}

	for cardIndex, card in pairs(cards) do
		if not CardNames[card:lower()] then
			error('Invalid Card "' .. card .. '"')
		end
		cards[cardIndex] = CardNames[card]
	end

	return cards
end

-- function to sort out winner/placements
function CustomMatchGroupInput._placementSortFunction(table, key1, key2)
	local opponent1 = table[key1]
	local opponent2 = table[key2]
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

function CustomMatchGroupInput.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

return CustomMatchGroupInput
