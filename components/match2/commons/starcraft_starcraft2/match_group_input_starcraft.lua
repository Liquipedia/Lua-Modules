---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate/Named')
local Variables = require('Module:Variables')

local config = Lua.loadDataIfExists('Module:Match/Config') or {}
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local Streams = Lua.import('Module:Links/Stream', {requireDevIfEnabled = true})

local defaultIcon

local _MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20
local _FACTIONS = mw.loadData('Module:Races')
local _ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local _CONVERT_STATUS_INPUT = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local _DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local _MAX_NUM_OPPONENTS = 2
local _MAX_NUM_PLAYERS = 30
local _MAX_NUM_VETOS = 6
local _MAX_NUM_VODGAMES = 9
local _DEFAULT_BEST_OF = 99
local _OPPONENT_MODE_TO_PARTIAL_MATCH_MODE = {
	solo = '1',
	duo = '2',
	trio = '3',
	quad = '4',
	team = 'team',
	literal = 'literal',
}
local _TBD_STRINGS = {
	'definitions',
	'tbd'
}

local getStarcraftFfaInputModule = FnUtil.memoize(function()
	return Lua.import('Module:MatchGroup/Input/Starcraft/Ffa', {requireDevIfEnabled = true})
end)

--[[
Module for converting input args of match group objects into LPDB records. This
module is specific to the Starcraft and Starcraft2 wikis.
]]
local StarcraftMatchGroupInput = {}

-- called from Module:MatchGroup
function StarcraftMatchGroupInput.processMatch(_, match)
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

function StarcraftMatchGroupInput._readDate(matchArgs)
	if matchArgs.date then
		local dateProps = MatchGroupInput.readDate(matchArgs.date)
		dateProps.dateexact = Logic.nilOr(Logic.readBoolOrNil(matchArgs.dateexact), dateProps.dateexact)
		Variables.varDefine('matchDate', dateProps.date)
		return dateProps
	else
		local suggestedDate = Variables.varDefaultMulti(
			'matchDate',
			'Match_date',
			'tournament_startdate',
			'tournament_enddate',
			'1970-01-01'
		)
		return {
			date = MatchGroupInput.getInexactDate(suggestedDate),
			dateexact = false,
		}
	end
end

function StarcraftMatchGroupInput._checkFinished(match)
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
		local matchUnixTime = tonumber(mw.getContentLanguage():formatDate('U', match.date))
		local threshold = match.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	return match
end

function StarcraftMatchGroupInput._getTournamentVars(match)
	match.noQuery = Variables.varDefault('disable_SMW_storage', 'false')
	match.cancelled = Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament', 'false'))
	match.type = Logic.emptyOr(match.type, Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_tickername'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
	match.icondark = Logic.emptyOr(match.iconDark, Variables.varDefault('tournament_icon_dark'))
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault('tournament_tier'))
	match.liquipediatiertype = Logic.emptyOr(match.liquipediatiertype, Variables.varDefault('tournament_tiertype'))
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	Variables.varDefine('headtohead', match.headtohead)
	match.featured = Logic.emptyOr(match.featured, Variables.varDefault('featured'))
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof'))
	Variables.varDefine('bestof', match.bestof)
	return match
end

function StarcraftMatchGroupInput._getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)

	return match
end

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

function StarcraftMatchGroupInput._getExtraData(match)
	local extradata
	if Logic.readBool(match.ffa) then
		extradata = getStarcraftFfaInputModule().getExtraData(match)
	else
		extradata = {
			noQuery = match.noQuery,
			matchsection = Variables.varDefault('matchsection'),
			comment = match.comment,
			featured = match.featured,
			casters = match.casters,
			headtohead = match.headtohead,
			ffa = 'false',
		}

		for vetoIndex = 1, _MAX_NUM_VETOS do
			extradata = StarcraftMatchGroupInput._getVeto(
				extradata,
				match['veto' .. vetoIndex],
				match['vetoplayer' .. vetoIndex] or match['vetoopponent' .. vetoIndex],
				vetoIndex
			)
		end

		for subGroupIndex = 1, _MAX_NUM_MAPS do
			extradata['subGroup' .. subGroupIndex .. 'header']
				= StarcraftMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
		end
	end

	match.extradata = extradata

	return match
end

function StarcraftMatchGroupInput._getVeto(extradata, map, vetoBy, vetoIndex)
	extradata['veto' .. vetoIndex] = (map ~= nil) and mw.ext.TeamLiquidIntegration.resolve_redirect(map) or nil
	extradata['veto' .. vetoIndex .. 'by'] = vetoBy

	return extradata
end

function StarcraftMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	local header = Logic.emptyOr(
		match['subGroup' .. subGroupIndex .. 'header'],
		match['subgroup' .. subGroupIndex .. 'header'],
		match['submatch' .. subGroupIndex .. 'header']
	)

	return String.isNotEmpty(header) and header or nil
end

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
	for index = 1, _MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if Logic.isNotEmpty(vodgame) and Logic.isNotEmpty(match['map' .. index]) then
			match['map' .. index].vod = match['map' .. index].vod or vodgame
		end
	end

	if string.find(match.mode, 'team') then
		match = StarcraftMatchGroupInput._subMatchStructure(match)
	end

	match = StarcraftMatchGroupInput._matchWinnerProcessing(match)

	return match
end

--[[

Misc. MatchInput functions
--> Winner, Walkover, Placement, Resulttype, Status
--> Sub-Match Structure

]]--
function StarcraftMatchGroupInput._matchWinnerProcessing(match)
	local bestof = tonumber(match.bestof or _DEFAULT_BEST_OF) or _DEFAULT_BEST_OF
	local walkover = match.walkover or ''
	local numberofOpponents = 0
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
			numberofOpponents = numberofOpponents + 1
			--determine opponent scores, status and placement
			--determine MATCH winner, resulttype and walkover
			--the following ignores the possibility of > 2 opponents
			--as > 2 opponents is only possible in ffa
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
						opponent.status = _CONVERT_STATUS_INPUT[score] or 'L'
					end
				elseif Table.includes(_ALLOWED_STATUSES, string.upper(walkover)) then
					if tonumber(match.winner or 0) == opponentIndex then
						opponent.status = 'W'
					else
						opponent.status = _CONVERT_STATUS_INPUT[string.upper(walkover)] or 'L'
					end
				else
					local score = string.upper(opponent.score or '')
					opponent.status = _CONVERT_STATUS_INPUT[score] or 'L'
					match.walkover = 'L'
				end
				opponent.score = -1
				match.finished = 'true'
				match.resulttype = 'default'
			elseif Logic.readBool(match.cancelled) then
				match.resulttype = 'np'
				match.finished = 'true'
				opponent.score = -1
			elseif _CONVERT_STATUS_INPUT[string.upper(opponent.score or '')] then
				if string.upper(opponent.score) == 'W' then
					match.winner = opponentIndex
					match.resulttype = 'default'
					match.finished = 'true'
					opponent.score = -1
					opponent.status = 'W'
				else
					match.resulttype = 'default'
					match.finished = 'true'
					match.walkover = _CONVERT_STATUS_INPUT[string.upper(opponent.score)]
					local score = string.upper(opponent.score)
					opponent.status = _CONVERT_STATUS_INPUT[score]
					opponent.score = -1
				end
			else
				opponent.status = 'S'
				opponent.score = tonumber(opponent.score or '') or
					tonumber(opponent.sumscore) or -1
				if opponent.score > bestof / 2 then
					match.finished = Logic.nilOr(match.finished, 'true')
					match.winner = tonumber(match.winner or '') or opponentIndex
				end
			end
		else
			break
		end
	end

	for opponentIndex = 1, numberofOpponents do
		local opponent = match['opponent' .. opponentIndex]
		if match.winner == 'draw' or tonumber(match.winner) == 0 or
				(match.opponent1.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
			match.finished = 'true'
			match.winner = 0
			match.resulttype = 'draw'
		end
		if
			tostring(match.winner) == tostring(opponentIndex) or
			match.resulttype == 'draw' or
			opponent.score == bestof / 2
		then
			opponent.placement = 1
		else
			opponent.placement = 2
		end
	end

	return match
end

function StarcraftMatchGroupInput._subMatchStructure(match)
	local subMatches = {}
	local numberOfMaps = 0

	for _, map, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		local subGroupIndex = map.subgroup

		--create a new sub-match if necessary
		subMatches[subGroupIndex] = subMatches[subGroupIndex] or {
			date = map.date,
			game = map.game,
			liquipediatier = map.liquipediatier,
			liquipediatiertype = map.liquipediatiertype,
			participants = Table.deepCopy(map.participants or {}),
			mode = map.mode,
			resulttype = 'submatch',
			subgroup = subGroupIndex,
			extradata = {
				header = Logic.emptyOr(
					match['subGroup' .. subGroupIndex .. 'header'],
					match['subgroup' .. subGroupIndex .. 'header'],
					match['submatch' .. subGroupIndex .. 'header']
				),
				noQuery = match.noQuery,
				matchsection = Variables.varDefault('matchsection'),
				featured = match.featured,
				isSubMatch = 'true',
				opponent1 = map.extradata.opponent1,
				opponent2 = map.extradata.opponent2,
			},
			type = match.type,
			scores = {0, 0},
			winner = 0
		}

		--adjust sub-match scores
		if map.map and String.startsWith(map.map, 'Submatch') then
			for opponentIndex, score in ipairs(subMatches[subGroupIndex].scores) do
				subMatches[subGroupIndex].scores[opponentIndex] = score + (map.scores[opponentIndex] or 0)
			end
		else
			local winner = tonumber(map.winner) or ''
			if subMatches[subGroupIndex].scores[winner] then
				subMatches[subGroupIndex].scores[winner] = subMatches[subGroupIndex].scores[winner] + 1
			end
		end
		numberOfMaps = mapIndex
	end

	for subMatchIndex, subMatch in ipairs(subMatches) do
		--get winner
		if subMatch.scores[1] > subMatch.scores[2] then
			subMatch.winner = 1
		elseif subMatch.scores[2] > subMatch.scores[1] then
			subMatch.winner = 2
		end

		match['map' .. (numberOfMaps + subMatchIndex)] = subMatch
	end

	return match
end

--[[

OpponentInput functions

]]--
function StarcraftMatchGroupInput._opponentInput(match)
	local opponentIndex = 1
	local opponent = match['opponent' .. opponentIndex]

	while opponentIndex <= _MAX_NUM_OPPONENTS and Logic.isNotEmpty(opponent) do
		opponent = Json.parseIfString(opponent)

		-- Convert byes to literals
		if
			string.lower(opponent.template or '') == 'bye'
			or string.lower(opponent.name or '') == 'bye'
		then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

		-- Fix legacy winner
		if String.isNotEmpty(opponent.win) then
			if String.isEmpty(match.winner) then
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

		--mark match as noQuery if it contains BYE/TBD/'' or Literal opponents
		local opponentName = string.lower(opponent.name or '')
		local playerName = string.lower(((opponent.match2players or {})[1] or {}).name or '')
		if
			opponent.type == Opponent.literal or
			Table.includes(_TBD_STRINGS, opponentName) or
			Table.includes(_TBD_STRINGS, playerName)
		then
			match.noQuery = 'true'
		end

		--set initial opponent sumscore
		opponent.sumscore =
			tonumber(opponent.extradata.advantage or '') or ''

		local mode = _OPPONENT_MODE_TO_PARTIAL_MATCH_MODE[opponent.type]
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

function StarcraftMatchGroupInput.ProcessSoloOpponentInput(opponent)
	local name = Logic.emptyOr(
		opponent.name,
		opponent.p1,
		opponent[1] or ''
	)
	local link = Logic.emptyOr(opponent.link, Variables.varDefault(name .. '_page'), name)
	link = mw.ext.TeamLiquidIntegration.resolve_redirect(link)
	local race = Logic.emptyOr(opponent.race, Variables.varDefault(name .. '_race'), '')
	local players = {}
	local flag = Logic.emptyOr(opponent.flag, Variables.varDefault(name .. '_flag'))
	players[1] = {
		displayname = name,
		name = link,
		flag = Flags.CountryName(flag),
		extradata = {faction = _FACTIONS[string.lower(race)] or 'u'}
	}

	return {
		type = opponent.type,
		name = link,
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

function StarcraftMatchGroupInput.ProcessDuoOpponentInput(opponent)
	opponent.p1 = opponent.p1 or ''
	opponent.p2 = opponent.p2 or ''
	opponent.link1 = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			opponent.p1link,
			Variables.varDefault(opponent.p1 .. '_page'),
			opponent.p1
		))
	opponent.link2 = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			opponent.p2link,
			Variables.varDefault(opponent.p2 .. '_page'),
			opponent.p2
		))
	if Logic.readBool(opponent.extradata.isarchon) then
		opponent.p1race = _FACTIONS[string.lower(opponent.race or '')] or 'u'
		opponent.p2race = opponent.p1race
	else
		opponent.p1race = _FACTIONS[string.lower(Logic.emptyOr(
				opponent.p1race,
				Variables.varDefault(opponent.p1 .. '_race'),
				''
			))] or 'u'
		opponent.p2race = _FACTIONS[string.lower(Logic.emptyOr(
				opponent.p2race,
				Variables.varDefault(opponent.p2 .. '_race'),
				''
			))] or 'u'
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
			extradata = {faction = _FACTIONS[string.lower(opponent['p' .. playerIndex .. 'race'])] or 'u'}
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

function StarcraftMatchGroupInput.ProcessOpponentInput(opponent, playernumber)
	local name = ''

	local players = {}
	for playerIndex = 1, playernumber do
		local playerName = opponent['p' .. playerIndex] or ''
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
				opponent['p' .. playerIndex .. 'link'],
				Variables.varDefault(playerName .. '_page'),
				playerName
			))
		local race = Logic.emptyOr(
			opponent['p' .. playerIndex .. 'race'],
			Variables.varDefault(playerName .. '_race'),
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
			extradata = {faction = _FACTIONS[string.lower(race)] or 'u'}
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

function StarcraftMatchGroupInput.ProcessLiteralOpponentInput(opponent)
	local race = opponent.race or ''
	local flag = opponent.flag or ''

	local players = {}
	if String.isEmpty(race) or String.isEmpty(flag) then
		players[1] = {
			displayname = opponent[1],
			name = '',
			flag = Flags.CountryName(flag),
			extradata = {faction = _FACTIONS[string.lower(race)] or 'u'}
		}
		local extradata = opponent.extradata or {}
		extradata.hasRaceOrFlag = true
	end

	return {
		type = opponent.type,
		name = opponent[1],
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

function StarcraftMatchGroupInput._getManuallyEnteredPlayers(playerData)
	local players = {}
	playerData = Json.parseIfString(playerData) or {}
	for playerIndex = 1, _MAX_NUM_PLAYERS do
		local name = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
				playerData['p' .. playerIndex .. 'link'],
				playerData['p' .. playerIndex],
				''
			))
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

function StarcraftMatchGroupInput._getPlayersFromVariables(teamName)
	local players = {}
	for playerIndex = 1, _MAX_NUM_PLAYERS do
		local name = Variables.varDefault(teamName .. '_p' .. playerIndex)
		if Logic.isNotEmpty(name) then
			local flag = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
			players[playerIndex] = {
				name = name,
				displayname = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'display'),
				flag = Flags.CountryName(flag),
				extradata = {faction = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'race')}
			}
		else
			break
		end
	end
	return players
end

function StarcraftMatchGroupInput.ProcessTeamOpponentInput(opponent, date)
	local customTeam = Logic.readBool(opponent.default)
		or Logic.readBool(opponent.defaulticon)
		or Logic.readBool(opponent.custom)
	local name
	local icon
	local iconDark

	if customTeam then
		if not defaultIcon then
			defaultIcon = require('Module:Brkts/WikiSpecific').defaultIcon
		end
		opponent.template = 'default'
		icon = defaultIcon
		name = Logic.emptyOr(opponent.link, opponent.name, opponent[1] or '')
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.display = Logic.emptyOr(opponent.name, opponent[1], '')
		opponent.extradata.short = Logic.emptyOr(opponent.short, opponent.name, opponent[1] or '')
		opponent.extradata.bracket = Logic.emptyOr(opponent.bracket, opponent.name, opponent[1] or '')
	else
		opponent.template = string.lower(Logic.emptyOr(opponent.template, opponent[1], ''))
		if String.isEmpty(opponent.template) then
			opponent.template = 'tbd'
		end
		name, icon, iconDark, opponent.template = StarcraftMatchGroupInput._processTeamTemplateInput(opponent.template, date)
	end
	name = TeamTemplate.resolveRedirect(name or '')
	local players = StarcraftMatchGroupInput._getManuallyEnteredPlayers(opponent.players)
	if Logic.isEmpty(players) then
		players = StarcraftMatchGroupInput._getPlayersFromVariables(name)
	end

	return {
		icon = icon,
		icondark = iconDark,
		template = opponent.template,
		type = opponent.type,
		name = name,
		score = opponent.score,
		extradata = opponent.extradata,
		match2players = players
	}
end

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

--[[

MapInput functions

]]--
function StarcraftMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])
	--redirect maps
	if map.map ~= 'TBD' then
		map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')
	end

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment or '',
		header = map.header or '',
		noQuery = match.noQuery,
		isSubMatch = 'false'
	}

	-- inherit stuff from match data
	map.type = match.type
	map.liquipediatier = match.liquipediatier
	map.liquipediatiertype = match.liquipediatiertype
	map.game = match.game
	map.date = match.date

	-- determine score, resulttype, walkover and winner
	map = StarcraftMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode + winnerfaction and loserfaction
	--(w/l race stuff only for 1v1 maps)
	map = StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, 2)

	-- set sumscore to 0 if it isn't a number
	if String.isEmpty(match.opponent1.sumscore) then
		match.opponent1.sumscore = 0
	end
	if String.isEmpty(match.opponent2.sumscore) then
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

function StarcraftMatchGroupInput._mapWinnerProcessing(map)
	map.scores = {}
	local hasManualScores = false
	local indexedScores = {}
	for scoreIndex = 1, _MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		local obj = {}
		if Logic.isNotEmpty(score) then
			hasManualScores = true
			score = _CONVERT_STATUS_INPUT[score] or score
			if Logic.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(_ALLOWED_STATUSES, score) then
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
		if String.isNotEmpty(map.walkover) then
			local walkoverInput = tonumber(map.walkover)
			if walkoverInput == 1 then
				map.winner = 1
			elseif walkoverInput == 2 then
				map.winner = 2
			elseif walkoverInput == 0 then
				map.winner = 0
			end
			map.walkover = Table.includes(_ALLOWED_STATUSES, map.walkover) and map.walkover or 'L'
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

function StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, numberOfOpponents)
	local participants = {}
	local mapMode = ''

	for opponentIndex = 1, numberOfOpponents do
		local opponentMapMode
		if match['opponent' .. opponentIndex].type == Opponent.team then
			local players = match['opponent' .. opponentIndex].match2players
			if Table.isEmpty(players) then
				opponentMapMode = 0
				break
			else
				participants, opponentMapMode = StarcraftMatchGroupInput._processTeamPlayerMapData(
					players,
					map,
					opponentIndex,
					participants
				)
			end
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
			opponentMapMode = tonumber(_OPPONENT_MODE_TO_PARTIAL_MATCH_MODE[match['opponent' .. opponentIndex].type])
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
			local opponentRaces, playerNameArray = StarcraftMatchGroupInput._fetchOpponentMapRacesAndNames(participants)
			if tonumber(map.winner or 0) == 1 then
				map.extradata.winnerfaction = opponentRaces[1]
				map.extradata.loserfaction = opponentRaces[2]
			elseif tonumber(map.winner or 0) == 2 then
				map.extradata.winnerfaction = opponentRaces[2]
				map.extradata.loserfaction = opponentRaces[1]
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

function StarcraftMatchGroupInput._fetchOpponentMapRacesAndNames(participants)
	local opponentRaces, playerNameArray = {}, {}
	for participantKey, participantData in pairs(participants) do
		local opponentIndex = tonumber(string.sub(participantKey, 1, 1))
		opponentRaces[opponentIndex] = participantData.faction
		playerNameArray[opponentIndex] = participantData.player
	end

	return opponentRaces, playerNameArray
end

function StarcraftMatchGroupInput._processDefaultPlayerMapData(players, map, opponentIndex, participants)
	local faction = string.lower(Logic.emptyOr(
		map['t' .. opponentIndex .. 'p1race'],
		map['race' .. opponentIndex],
		'u'
	))
	participants[opponentIndex .. '_1'] = {
		faction = _FACTIONS[faction] or players[1].extradata.faction or 'u',
		player = players[1].name
	}

	for playerIndex = 2, #players do
		faction = string.lower(Logic.emptyOr(
			map['t' .. opponentIndex .. 'p' .. playerIndex .. 'race'],
			'u'
		))
		participants[opponentIndex .. '_' .. playerIndex] = {
			faction = _FACTIONS[faction] or players[playerIndex].extradata.faction or 'u',
			player = players[playerIndex].name
		}
	end

	return participants
end

function StarcraftMatchGroupInput._processArchonPlayerMapData(players, map, opponentIndex, participants)
	local faction = string.lower(Logic.emptyOr(
		map['opponent' .. opponentIndex .. 'race'],
		map['race' .. opponentIndex],
		players[1].extradata.faction or 'u'
	))
	participants[opponentIndex .. '_1'] = {
		faction = _FACTIONS[faction] or 'u',
		player = players[1].name
	}

	participants[opponentIndex .. '_2'] = {
		faction = _FACTIONS[faction] or 'u',
		player = players[2].name
	}

	return participants
end

function StarcraftMatchGroupInput._processTeamPlayerMapData(players, map, opponentIndex, participants)
	local amountOfTbds = 0
	local playerData = {}

	for playerIndex = 1, 4 do
		local playerKey = 't' .. opponentIndex .. 'p' .. playerIndex
		if Logic.isNotEmpty(map[playerKey]) then
			if map[playerKey] ~= 'TBD' and map[playerKey] ~= 'TBA' then
				-- allows fetching the link of the player from preset wiki vars
				local mapPlayer = mw.ext.TeamLiquidIntegration.resolve_redirect(
					map[playerKey .. 'link'] or
					Variables.varDefault(map[playerKey] .. '_page') or
					map[playerKey]
				)
				if Logic.readBool(map['opponent' .. opponentIndex .. 'archon']) then
					playerData[mapPlayer] = {
						faction = _FACTIONS[string.lower(Logic.emptyOr(
								map['t' .. opponentIndex .. 'race'],
								map['opponent' .. opponentIndex .. 'race'],
								Logic.emptyOr(
									map[playerKey .. 'race'],
									'u'
								)
							))] or 'u',
						position = playerIndex
					}
				else
					playerData[mapPlayer] = {
						faction = _FACTIONS[string.lower(Logic.emptyOr(map[playerKey .. 'race'], 'u'))] or 'u',
						position = playerIndex
					}
				end
			else
				amountOfTbds = amountOfTbds + 1
			end
		else
			break
		end
	end

	local numberOfParticipants = 0
	for playerIndex, player in pairs(players) do
		if player and playerData[player.name] then
			numberOfParticipants = numberOfParticipants + 1
			local faction = playerData[player.name].faction ~= 'u'
				and playerData[player.name].faction
				or player.extradata.faction or 'u'
			participants[opponentIndex .. '_' .. playerIndex] = {
				faction = faction,
				player = player.name,
				position = playerData[player.name].position,
				flag = Flags.CountryName(player.flag),
			}
			end
	end

	numberOfParticipants = numberOfParticipants + amountOfTbds
	for tbdIndex = 1, amountOfTbds do
		participants[opponentIndex .. '_' .. (#players + tbdIndex)] = {
			faction = 'u',
			player = 'TBD'
		}
	end

	local opponentMapMode
	if numberOfParticipants == 2 and Logic.readBool(map['opponent' .. opponentIndex .. 'archon']) then
		opponentMapMode = 'Archon'
	elseif numberOfParticipants == 2 and Logic.readBool(map['opponent' .. opponentIndex .. 'duoSpecial']) then
		opponentMapMode = '2S'
	elseif numberOfParticipants == 4 and Logic.readBool(map['opponent' .. opponentIndex .. 'quadSpecial']) then
		opponentMapMode = '4S'
	else
		opponentMapMode = numberOfParticipants
	end

	return participants, opponentMapMode
end

-- function to sort out winner/placements
function StarcraftMatchGroupInput._placementSortFunction(table, key1, key2)
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
		elseif Table.includes(_DEFAULT_LOSS_STATUSES, opponent1.status) then return false
		elseif opponent2.status == 'W' then return false
		elseif Table.includes(_DEFAULT_LOSS_STATUSES, opponent2.status) then return true
		else return true end
	end
end

return StarcraftMatchGroupInput
