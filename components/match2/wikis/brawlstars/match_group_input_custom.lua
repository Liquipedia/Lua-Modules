---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local _frame

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(frame, match)
	_frame = frame
	Table.mergeInto(
		match,
		matchFunctions.readDate(match)
	)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(frame, map)
	_frame = frame
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)
	--map = mapFunctions.getParticipantsData(map)

	return map
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processOpponent(frame, opponent)
	_frame = frame
	if not Logic.isEmpty(opponent.template) and
		string.lower(opponent.template) == 'bye' then
			opponent.name = 'BYE'
			opponent.type = 'literal'
	end

	--fix for legacy conversion
	--local players = opponent.players or opponent.match2players
	--if opponent.type == 'solo' and players == nil then
		--opponent = opponentFunctions.getSoloFromLegacy(opponent)
	--end

	return opponent
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(frame, player)
	_frame = frame
	return player
end

--
--
-- function to sort out winner/placements
function CustomMatchGroupInput._placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == 'S'
	local op2norm = op2.status == 'S'
	if op1norm then
		if op2norm then
			local op1setwins = CustomMatchGroupInput._getSetWins(op1)
			local op2setwins = CustomMatchGroupInput._getSetWins(op2)
			if op1setwins + op2setwins > 0 then
				return op1setwins > op2setwins
			else
				return tonumber(op1.score) > tonumber(op2.score)
			end
		else return true end
	else
		if op2norm then return false
		elseif op1.status == 'W' then return true
		elseif op1.status == 'DQ' then return false
		elseif op2.status == 'W' then return false
		elseif op2.status == 'DQ' then return true
		else return true end
	end
end

function CustomMatchGroupInput._getSetWins(opp)
	local extradata = opp.extradata or {}
	local set1win = extradata.set1win and 1 or 0
	local set2win = extradata.set2win and 1 or 0
	local set3win = extradata.set3win and 1 or 0
	local sum = set1win + set2win + set3win
	return sum
end

--
-- match related functions
--

function matchFunctions.readDate(matchArgs)
	return matchArgs.date
		and MatchGroupInput.readDate(matchArgs.date)
		or {date = MatchGroupInput.getInexactDate(), dateexact = false}
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.type = Logic.emptyOr(match.type, Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_ticker_name'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
	match.icondark = Logic.emptyOr(match.iconDark, Variables.varDefault('tournament_icon_dark'))
	match.liquipediatier = Logic.emptyOr(
		match.liquipediatier,
		Variables.varDefault('tournament_lptier'),
		Variables.varDefault('tournament_tier')
	)
	match.liquipediatiertype = Logic.emptyOr(
		match.liquipediatiertype,
		Variables.varDefault('tournament_tiertype')
	)
	return match
end

function matchFunctions.getVodStuff(match)
	match.stream = match.stream or {}
	match.stream = {
		stream = Logic.emptyOr(match.stream.stream, Variables.varDefault('stream')),
		twitch = Logic.emptyOr(match.stream.twitch or match.twitch, Variables.varDefault('twitch')),
		twitch2 = Logic.emptyOr(match.stream.twitch2 or match.twitch2, Variables.varDefault('twitch2')),
		afreeca = Logic.emptyOr(match.stream.afreeca or match.afreeca, Variables.varDefault('afreeca')),
		afreecatv = Logic.emptyOr(match.stream.afreecatv or match.afreecatv, Variables.varDefault('afreecatv')),
		dailymotion = Logic.emptyOr(match.stream.dailymotion or match.dailymotion, Variables.varDefault('dailymotion')),
		douyu = Logic.emptyOr(match.stream.douyu or match.douyu, Variables.varDefault('douyu')),
		smashcast = Logic.emptyOr(match.stream.smashcast or match.smashcast, Variables.varDefault('smashcast')),
		youtube = Logic.emptyOr(match.stream.youtube or match.youtube, Variables.varDefault('youtube')),
		trovo = Logic.emptyOr(match.stream.trovo or match.trovo, Variables.varDefault('trovo')),
		facebook = Logic.emptyOr(match.stream.facebook or match.facebook, Variables.varDefault('facebook')),
	}
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	-- apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if not Logic.isEmpty(vodgame) then
			local map = match['map' .. index] or {}
			map.vod = map.vod or vodgame
			match['map' .. index] = map
		end
	end
	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		matchsection = Variables.varDefault('matchsection'),
		comment = match.comment,
		ban1 = match.ban1,
		ban2 = match.ban2,
		ban3 = match.ban3,
		ban4 = match.ban4,
		ban5 = match.ban5,
		ban6 = match.ban6,
		ban1opponent = match.ban1opponent,
		ban2opponent = match.ban2opponent,
		ban3opponent = match.ban3opponent,
		ban4opponent = match.ban4opponent,
		ban5opponent = match.ban5opponent,
		ban6opponent = match.ban6opponent,
	}
	return match
end

function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false

	local sumscores = {}
	for _, map in Table.iter.pairsByPrefix(args, 'map') do
		sumscores[map.winner] = (sumscores[map.winner] or 0) + 1
	end

	local bestof = tonumber(args.bestof or 5) or 5
	local firstTo = math.ceil(bestof / 2)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			--retrieve name and icon for teams from team templates
			if opponent.type == 'team' and
				not Logic.isEmpty(opponent.template, args.date) then
					local name, icon, template = opponentFunctions.getTeamNameAndIcon(opponent.template, args.date)
					opponent.template = template
					opponent.name = mw.ext.TeamLiquidIntegration.resolve_redirect(
						opponent.name or name or
						opponentFunctions.getTeamName(opponent.template)
						or '')
					opponent.icon = opponent.icon or icon or opponentFunctions.getIconName(opponent.template)
			end
			opponent.score = opponent.score or sumscores[opponentIndex]

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
				if firstTo <= tonumber(opponent.score) then
					args.finished = true
				end
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
				args.finished = true
			end

			--set Walkover from Opponent status
			args.walkover = args.walkover or STATUS_TO_WALKOVER[opponent.status]

			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == 'team' and not Logic.isEmpty(opponent.name) then
				args = matchFunctions.getPlayers(args, opponentIndex, opponent.name)
			end
		end
	end

	--set resulttype to 'default' if walkover is set
	if args.walkover then
		args.resulttype = 'default'
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(args.finished) then
		local currentUnixTime = os.time(os.date('!*t'))
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', args.date))
		local threshold = args.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			args.finished = true
		end
	end

	-- apply placements and winner if finshed
	if Logic.readBool(args.finished) then
		local placement = 1
		-- luacheck: push ignore
		for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
			if placement == 1 then
				args.winner = opponentIndex
			end
			opponent.placement = placement
			args['opponent' .. opponentIndex] = opponent
			placement = placement + 1
		end
	-- luacheck: pop
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			args['opponent' .. opponentIndex] = opponent
		end
	end
	return args
end

function matchFunctions.getPlayers(match, opponentIndex, teamName)
	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		local player = Json.parseIfString(match['opponent' .. opponentIndex .. '_p' .. playerIndex]) or {}
		player.name = player.name or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		if not Table.isEmpty(player) then
			match['opponent' .. opponentIndex .. '_p' .. playerIndex] = player
		end
	end
	return match
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)
	local bestof = tonumber(map.bestof or 3) or 3
	map.extradata = {
		bestof = bestof,
		comment = map.comment,
		header = map.header,
	}
	map.bestof = bestof
	return map
end

function mapFunctions.getScoresAndWinner(map)
	map.score1 = tonumber(map.score1 or '')
	map.score2 = tonumber(map.score2 or '')
	map.scores = { map.score1, map.score2 }
	local firstTo = math.ceil( map.bestof / 2 )
	if (map.score1 or 0) >= firstTo then
		map.winner = 1
		map.finished = true
	elseif (map.score2 or 0) >= firstTo then
		map.winner = 2
		map.finished = true
	end

	return map
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', '3v3'))
	map.type = Logic.emptyOr(map.type, Variables.varDefault('tournament_type'))
	map.tournament = Logic.emptyOr(map.tournament, Variables.varDefault('tournament_name'))
	map.tickername = Logic.emptyOr(map.tickername, Variables.varDefault('tournament_ticker_name'))
	map.shortname = Logic.emptyOr(map.shortname, Variables.varDefault('tournament_shortname'))
	map.series = Logic.emptyOr(map.series, Variables.varDefault('tournament_series'))
	map.icon = Logic.emptyOr(map.icon, Variables.varDefault('tournament_icon'))
	map.icondark = Logic.emptyOr(map.iconDark, Variables.varDefault('tournament_icon_dark'))
	map.liquipediatier = Logic.emptyOr(map.liquipediatier, Variables.varDefault('tournament_tier'))
	return map
end

function mapFunctions.getParticipantsData(map)
	local participants = map.participants or {}
	map.participants = participants
	return map
end

--
-- opponent related functions
--
function opponentFunctions.getTeamNameAndIcon(template, date)
	local icon, team
	template = string.lower(template or ''):gsub('_', ' ')
	if template ~= '' and template ~= 'noteam' and
		mw.ext.TeamTemplate.teamexists(template) then

		local templateData = mw.ext.TeamTemplate.raw(template, date)
		icon = templateData.image
		if icon == '' then
			icon = templateData.legacyimage
		end
		team = templateData.page
		template = templateData.templatename or template
	end

	return team, icon, template
end

--the following 2 functions are a fallback
--they are only useful if the team template doesn't exist
--in the team template extension
function opponentFunctions.getTeamName(template)
	if template ~= nil then
		local team = Template.expandTemplate(_frame, 'Team', { template })
		team = team:gsub('%&', '')
		team = String.split(team, 'link=')[2]
		team = String.split(team, ']]')[1]
		return team
	else
		return nil
	end
end

function opponentFunctions.getIconName(template)
	if template ~= nil then
		local icon = Template.expandTemplate(_frame, 'Team', { template })
		icon = icon:gsub('%&', '')
		icon = String.split(icon, 'File:')[2]
		icon = String.split(icon, '|')[1]
		return icon
	else
		return nil
	end
end

--maybe needed for legacy conversion to work for solo brackets
function opponentFunctions.getSoloFromLegacy(opponent)
	local player = {
		name = opponent.name,
		displayname = opponent.displayname or opponent.name,
		flag = opponent.flag
	}
	opponent.match2players = {player}
	opponent.name = nil
	return opponent
end

return CustomMatchGroupInput
