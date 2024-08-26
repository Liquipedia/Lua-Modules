---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft/deprecated
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@deprecated
---only used for the ffa part until that gets cleaned up too


local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local config = Lua.requireIfExists('Module:Match/Config', {loadData = true}) or {}
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20
local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local CONVERT_STATUS_INPUT = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 30
local MAX_NUM_VODGAMES = 9
local DEFAULT_BEST_OF = 99
local OPPONENT_MODE_TO_PARTIAL_MATCH_MODE = {
	solo = '1',
	duo = '2',
	trio = '3',
	quad = '4',
	team = 'team',
	literal = 'literal',
}
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])
local TBD = 'tbd'
local TBA = 'tba'

local getStarcraftFfaInputModule = FnUtil.memoize(function()
	return Lua.import('Module:MatchGroup/Input/Starcraft/Ffa')
end)

---Module for converting input args of match group objects into LPDB records.
---This module is specific to the Starcraft and Starcraft2 wikis.
local StarcraftMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function StarcraftMatchGroupInput.processMatch(match, options)
	Table.mergeInto(
		match,
		StarcraftMatchGroupInput._readDate(match)
	)
	match = StarcraftMatchGroupInput._getTournamentVars(match)
	if Logic.readBool(match.ffa) then
		match = getStarcraftFfaInputModule().adjustData(match)
	else
		match = StarcraftMatchGroupInput._adjustData(match)
	end
	match = StarcraftMatchGroupInput._checkFinished(match)
	match = StarcraftMatchGroupInput._getVodStuff(match)
	match = StarcraftMatchGroupInput._getLinks(match)
	match = StarcraftMatchGroupInput._getExtraData(match)

	return match
end

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function StarcraftMatchGroupInput._readDate(matchArgs)
	local dateProps = MatchGroupInputUtil.readDate(matchArgs.date, {
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
---@return table
function StarcraftMatchGroupInput._checkFinished(match)
	if Logic.readBoolOrNil(match.finished) == false then
		match.finished = false
		return match
	elseif Logic.readBool(match.finished) then
		match.finished = true
	elseif Logic.isNotEmpty(match.winner) then
		match.finished = true
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	if match.finished ~= true then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	return match
end

---@param match table
---@return table
function StarcraftMatchGroupInput._getTournamentVars(match)
	match.cancelled = Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament', 'false'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	Variables.varDefine('headtohead', match.headtohead)
	match.publishertier = Logic.emptyOr(match.featured, Variables.varDefault('tournament_publishertier'))
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof'))
	Variables.varDefine('bestof', match.bestof)

	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@return table
function StarcraftMatchGroupInput._getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)

	return match
end

---@param match table
---@return table
function StarcraftMatchGroupInput._getLinks(match)
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

---@param match table
---@return table
function StarcraftMatchGroupInput._getExtraData(match)
	local extradata
	if Logic.readBool(match.ffa) then
		match.extradata = getStarcraftFfaInputModule().getExtraData(match)
		return match
	end

	extradata = {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
		headtohead = match.headtohead,
		ffa = 'false',
	}

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		StarcraftMatchGroupInput._getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	for subGroupIndex = 1, MAX_NUM_MAPS do
		extradata['subGroup' .. subGroupIndex .. 'header']
			= StarcraftMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	end

	match.extradata = extradata

	return match
end

---@param extradata table
---@param map string
---@param match table
---@param prefix string
---@param vetoIndex integer
function StarcraftMatchGroupInput._getVeto(extradata, map, match, prefix, vetoIndex)
	extradata[prefix] = map and mw.ext.TeamLiquidIntegration.resolve_redirect(map) or nil
	extradata[prefix .. 'by'] = match['vetoplayer' .. vetoIndex] or match['vetoopponent' .. vetoIndex]
	extradata[prefix .. 'displayname'] = match[prefix .. 'displayName']
end

---@param subGroupIndex integer
---@param match table
---@return string?
function StarcraftMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	local header = Logic.emptyOr(
		match['subGroup' .. subGroupIndex .. 'header'],
		match['subgroup' .. subGroupIndex .. 'header'],
		match['submatch' .. subGroupIndex .. 'header']
	)

	return String.nilIfEmpty(header)
end

---@param match table
---@return table
function StarcraftMatchGroupInput._adjustData(match)
	--parse opponents + set base sumscores + determine match mode
	match.mode = ''
	match = StarcraftMatchGroupInput._opponentInput(match)

	--main processing done here
	local subGroupIndex = 0
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		match, subGroupIndex = StarcraftMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	end

	--apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if Logic.isNotEmpty(vodgame) and Logic.isNotEmpty(match['map' .. index]) then
			match['map' .. index].vod = match['map' .. index].vod or vodgame
		end
	end

	match = StarcraftMatchGroupInput._matchWinnerProcessing(match)

	return match
end

---@param match table
---@return table
function StarcraftMatchGroupInput._matchWinnerProcessing(match)
	local bestof = tonumber(match.bestof) or DEFAULT_BEST_OF
	local walkover = match.walkover or ''
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

	StarcraftMatchGroupInput._determineWinnerIfMissing(match)

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

	return match
end

---@param match table
---@return table
function StarcraftMatchGroupInput._determineWinnerIfMissing(match)
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
function StarcraftMatchGroupInput._opponentInput(match)
	local opponentIndex = 1
	local opponent = match['opponent' .. opponentIndex]

	while opponentIndex <= MAX_NUM_OPPONENTS and Logic.isNotEmpty(opponent) do
		opponent = Json.parseIfString(opponent)

		-- Convert byes to literals
		if
			string.lower(opponent.template or '') == 'bye'
			or string.lower(opponent.name or '') == 'bye'
		then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

		-- Fix legacy winner
		if Logic.isNotEmpty(opponent.win) then
			if Logic.isEmpty(match.winner) then
				match.winner = tostring(opponentIndex)
			else
				match.winner = '0'
			end
			opponent.win = nil
		end

		-- Opponent processing (first part)
		-- Sort out extradata
		opponent.extradata = {
			advantage = opponent.advantage,
			penalty = opponent.penalty,
			score2 = opponent.score2,
			isarchon = opponent.isarchon
		}

		--process input depending on type
		if opponent.type == Opponent.solo then
			opponent =
				StarcraftMatchGroupInput.ProcessSoloOpponentInput(opponent)
		elseif opponent.type == Opponent.duo then
			opponent = StarcraftMatchGroupInput.ProcessDuoOpponentInput(opponent)
		elseif opponent.type == Opponent.trio then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 3)
		elseif opponent.type == Opponent.quad then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 4)
		elseif opponent.type == Opponent.team then
			opponent = StarcraftMatchGroupInput.ProcessTeamOpponentInput(opponent, match.date)
		elseif opponent.type == Opponent.literal then
			opponent = StarcraftMatchGroupInput.ProcessLiteralOpponentInput(opponent)
		else
			error('Unsupported Opponent Type')
		end

		--set initial opponent sumscore
		opponent.sumscore =
			tonumber(opponent.extradata.advantage) or tonumber('-' .. (opponent.extradata.penalty or ''))

		local mode = OPPONENT_MODE_TO_PARTIAL_MATCH_MODE[opponent.type]
		if mode == '2' and Logic.readBool(opponent.extradata.isarchon) then
			mode = 'Archon'
		end

		match.mode = match.mode .. (opponentIndex ~= 1 and '_' or '') .. mode

		match['opponent' .. opponentIndex] = opponent

		opponentIndex = opponentIndex + 1
		opponent = match['opponent' .. opponentIndex]
	end

	return match
end

---@param opponent table
---@return table
function StarcraftMatchGroupInput.ProcessSoloOpponentInput(opponent)
	local name = Logic.emptyOr(
		opponent.name,
		opponent.p1,
		opponent[1]
	) or ''
	local link = Logic.emptyOr(opponent.link, Variables.varDefault(name .. '_page')) or name
	link = mw.ext.TeamLiquidIntegration.resolve_redirect(link):gsub(' ', '_')
	local faction = Logic.emptyOr(opponent.race, Variables.varDefault(name .. '_faction'))
	local players = {}
	local flag = Logic.emptyOr(opponent.flag, Variables.varDefault(name .. '_flag'))
	players[1] = {
		displayname = name,
		name = link,
		flag = Flags.CountryName(flag),
		extradata = {faction = Faction.read(faction) or Faction.defaultFaction}
	}

	return {
		type = opponent.type,
		name = link,
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param opponent table
---@return table
function StarcraftMatchGroupInput.ProcessDuoOpponentInput(opponent)
	opponent.p1 = opponent.p1 or ''
	opponent.p2 = opponent.p2 or ''
	opponent.link1 = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			opponent.p1link,
			Variables.varDefault(opponent.p1 .. '_page')
		) or opponent.p1):gsub(' ', '_')
	opponent.link2 = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			opponent.p2link,
			Variables.varDefault(opponent.p2 .. '_page')
		) or opponent.p2):gsub(' ', '_')
	if Logic.readBool(opponent.extradata.isarchon) then
		opponent.p1faction = Faction.read(opponent.race) or Faction.defaultFaction
		opponent.p2faction = opponent.p1faction
	else
		opponent.p1faction = Faction.read(Logic.emptyOr(
				opponent.p1race,
				Variables.varDefault(opponent.p1 .. '_faction')
			)) or Faction.defaultFaction
		opponent.p2faction = Faction.read(Logic.emptyOr(
				opponent.p2race,
				Variables.varDefault(opponent.p2 .. '_faction')
			)) or Faction.defaultFaction
	end

	local players = {}
	for playerIndex = 1, 2 do
		local flag = Logic.emptyOr(
			opponent['p' .. playerIndex .. 'flag'],
			Variables.varDefault(opponent['p' .. playerIndex] .. '_flag')
		)

		players[playerIndex] = {
			displayname = opponent['p' .. playerIndex],
			name = opponent['link' .. playerIndex],
			flag = Flags.CountryName(flag),
			extradata = {faction = Faction.read(opponent['p' .. playerIndex .. 'faction']) or Faction.defaultFaction}
		}
	end
	local name = opponent.link1 .. ' / ' .. opponent.link2

	return {
		type = opponent.type,
		name = name,
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param opponent table
---@param playernumber integer
---@return table
function StarcraftMatchGroupInput.ProcessOpponentInput(opponent, playernumber)
	local name = ''

	local players = {}
	for playerIndex = 1, playernumber do
		local playerName = opponent['p' .. playerIndex] or ''
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
				opponent['p' .. playerIndex .. 'link'],
				Variables.varDefault(playerName .. '_page')
			) or playerName):gsub(' ', '_')
		local faction = Logic.emptyOr(
			opponent['p' .. playerIndex .. 'race'],
			Variables.varDefault(playerName .. '_faction'),
			''
		)
		name = name .. (playerIndex ~= 1 and ' / ' or '') .. link
		local flag = Logic.emptyOr(
			opponent['p' .. playerIndex .. 'flag'],
			Variables.varDefault((opponent['p' .. playerIndex] or '') .. '_flag')
		)

		players[playerIndex] = {
			displayname = playerName,
			name = link,
			flag = Flags.CountryName(flag),
			extradata = {faction = Faction.read(faction) or Faction.defaultFaction}
		}
	end

	return {
		type = opponent.type,
		name = name,
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param opponent table
---@return table
function StarcraftMatchGroupInput.ProcessLiteralOpponentInput(opponent)
	local faction = opponent.race or ''
	local flag = opponent.flag or ''

	local players = {}
	if String.isNotEmpty(faction) or String.isNotEmpty(flag) then
		players[1] = {
			displayname = opponent[1],
			name = '',
			flag = Flags.CountryName(flag),
			extradata = {faction = Faction.read(faction) or Faction.defaultFaction}
		}
		local extradata = opponent.extradata or {}
		extradata.hasFactionOrFlag = true
	end

	return {
		type = opponent.type,
		name = opponent[1],
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param playerData string|table?
---@return table
function StarcraftMatchGroupInput._getManuallyEnteredPlayers(playerData)
	local players = {}
	playerData = Json.parseIfString(playerData) or {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		local name = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
				playerData['p' .. playerIndex .. 'link'],
				playerData['p' .. playerIndex]
			) or ''):gsub(' ', '_')
		if String.isNotEmpty(name) then
			players[playerIndex] = {
				name = name,
				displayname = playerData['p' .. playerIndex],
				flag = Flags.CountryName(playerData['p' .. playerIndex .. 'flag']),
				extradata = {
					faction = playerData['p' .. playerIndex .. 'race'],
					position = playerIndex
				}
			}
		else
			break
		end
	end

	return players
end

---@param teamName string
---@return table
function StarcraftMatchGroupInput._getPlayersFromVariables(teamName)
	local players = {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		local prefix = teamName .. '_p' .. playerIndex
		local name = Variables.varDefault(prefix)
		if Logic.isNotEmpty(name) then
			---@cast name -nil
			local player = {
				name = name:gsub(' ', '_'),
				displayname = Variables.varDefault(prefix .. 'dn'),
				flag = Flags.CountryName(Variables.varDefault(prefix .. 'flag')),
				extradata = {faction = Variables.varDefault(prefix .. 'faction')}
			}
			if player.displayname then
				Variables.varDefine(player.displayname .. '_page', player.name)
			end
			table.insert(players, player)
		else
			break
		end
	end
	return players
end

---@param opponent table
---@param date string?
---@return table
function StarcraftMatchGroupInput.ProcessTeamOpponentInput(opponent, date)
	local name, icon, iconDark

	opponent.template = string.lower(Logic.emptyOr(opponent.template, opponent[1], 'tbd')--[[@as string]])

	name, icon, iconDark, opponent.template = StarcraftMatchGroupInput._processTeamTemplateInput(opponent.template, date)

	local players = StarcraftMatchGroupInput._getManuallyEnteredPlayers(opponent.players)
	if Logic.isEmpty(players) then
		players = StarcraftMatchGroupInput._getPlayersFromVariables(name)
	end

	return {
		icon = icon,
		icondark = iconDark,
		template = opponent.template,
		type = opponent.type,
		name = name:gsub(' ', '_'),
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

---@param template string?
---@param date string?
---@return string?
---@return string?
---@return string?
---@return string
function StarcraftMatchGroupInput._processTeamTemplateInput(template, date)
	local icon, name, iconDark
	template = string.lower(template or ''):gsub('_', ' ')
	if String.isNotEmpty(template) and template ~= 'noteam' and
		mw.ext.TeamTemplate.teamexists(template) then

		local templateData = mw.ext.TeamTemplate.raw(template, date)
		icon = templateData.image
		iconDark = templateData.imagedark
		if String.isEmpty(icon) then
			icon = templateData.legacyimage
		end
		if String.isEmpty(iconDark) then
			iconDark = templateData.legacyimagedark
		end
		name = templateData.page
		template = templateData.templatename or template
	end

	return name, icon, iconDark, template
end

--MapInput functions

---@param match table
---@param mapIndex integer
---@param subGroupIndex integer
---@return table
---@return integer
function StarcraftMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])
	--redirect maps
	if map.map ~= 'TBD' then
		map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')
	end

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		displayname = map.mapDisplayName,
		header = map.header,
		server = map.server,
	}

	-- determine score, resulttype, walkover and winner
	map = StarcraftMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode + winnerfaction and loserfaction
	--(w/l faction stuff only for 1v1 maps)
	map = StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, 2)

	-- set sumscore to 0 if it isn't a number
	if Logic.isEmpty(match.opponent1.sumscore) then
		match.opponent1.sumscore = 0
	end
	if Logic.isEmpty(match.opponent2.sumscore) then
		match.opponent2.sumscore = 0
	end

	--adjust sumscore for winner opponent
	if (tonumber(map.winner or 0) or 0) > 0 then
		match['opponent' .. map.winner].sumscore =
			match['opponent' .. map.winner].sumscore + 1
	end

	-- handle subgroup stuff if team match
	if string.find(match.mode, 'team') then
		map.subgroup = tonumber(map.subgroup or '')
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

---@param map table
---@return table
function StarcraftMatchGroupInput._mapWinnerProcessing(map)
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
		for scoreIndex, _ in Table.iter.spairs(indexedScores, StarcraftMatchGroupInput._placementSortFunction) do
			if not tonumber(map.winner or '') then
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
			map.scores = {0, 0}
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

-- function to sort out winner/placements
---@param tbl table
---@param key1 string|integer
---@param key2 string|integer
---@return boolean
function StarcraftMatchGroupInput._placementSortFunction(tbl, key1, key2)
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

return StarcraftMatchGroupInput
