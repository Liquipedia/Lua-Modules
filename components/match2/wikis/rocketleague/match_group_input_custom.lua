---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local p = require('Module:Brkts/WikiSpecific/Base')

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local getIconName = require('Module:IconName').luaGet

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20
local _RESULT_TYPE_DRAW = 'draw'
local _EARNINGS_LIMIT_FOR_FEATURED = 10000
local _CURRENT_YEAR = os.date('%Y')

local _frame
local globalVars = PageVariableNamespace()

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

-- called from Module:MatchGroup
function p.processMatch(frame, match)
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
function p.processMap(frame, map)
	_frame = frame
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)
	map = mapFunctions.getParticipantsData(map)

	return map
end

-- called from Module:Match/Subobjects
function p.processOpponent(frame, opponent)
	_frame = frame
	if not Logic.isEmpty(opponent.template) and
		string.lower(opponent.template) == 'bye' then
			opponent.name = 'BYE'
			opponent.type = 'literal'
	end

	--fix for legacy conversion
	local players = opponent.players or opponent.match2players
	if opponent.type == 'solo' and players == nil then
		opponent = opponentFunctions.getSoloFromLegacy(opponent)
	end

	--score2 & score3 support for every match
	local score2 = tonumber(opponent.score2 or '')
	local score3 = tonumber(opponent.score3 or '')
	if score2 then
		opponent.extradata = {
			score2 = score2,
			score3 = score3,
			set1win = Logic.readBool(opponent.set1win),
			set2win = Logic.readBool(opponent.set2win),
			set3win = Logic.readBool(opponent.set3win),
			additionalScores = true
		}
	end

	return opponent
end

-- called from Module:Match/Subobjects
function p.processPlayer(frame, player)
	_frame = frame
	return player
end

--
--
-- function to sort out winner/placements
function p._placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == 'S'
	local op2norm = op2.status == 'S'
	if op1norm then
		if op2norm then
			local op1setwins = p._getSetWins(op1)
			local op2setwins = p._getSetWins(op2)
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

function p._getSetWins(opp)
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
		or {
			date = MatchGroupInput.getInexactDate(globalVars:get('tournament_enddate')),
			dateexact = false,
		}
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '3v3'))
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
		youtube = Logic.emptyOr(match.stream.youtube or match.youtube, Variables.varDefault('youtube'))
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
	local opponent1 = match.opponent1 or {}
	local opponent2 = match.opponent2 or {}
	match.extradata = {
		matchsection = Variables.varDefault('matchsection'),
		team1icon = getIconName(opponent1.template or ''),
		team2icon = getIconName(opponent2.template or ''),
		lastgame = Variables.varDefault('last_game'),
		comment = match.comment,
		octane = match.octane,
		liquipediatier2 = Variables.varDefault('tournament_tier2'),
		isconverted = 0,
		isfeatured = matchFunctions.isFeatured(match)
	}
	return match
end

function matchFunctions.isFeatured(match)
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	if opponent1.type ~= 'team' or opponent2.type ~= 'team' then
		return false
	end

	if
		tonumber(match.liquipediatier or '') == 1
		or tonumber(match.liquipediatier or '') == 2
		or not String.isEmpty(Variables.varDefault('tournament_rlcs_premier'))
		or not String.isEmpty(Variables.varDefault('match_featured_override'))
	then
		return true
	end

	if matchFunctions.currentEarnings(opponent1.name) >= _EARNINGS_LIMIT_FOR_FEATURED then
		return true
	elseif matchFunctions.currentEarnings(opponent2.name) >= _EARNINGS_LIMIT_FOR_FEATURED then
		return true
	end
	return false
end

function matchFunctions.currentEarnings(name)
	if String.isEmpty(name) then
		return 0
	end
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[name::' .. name .. ']]',
		query = 'extradata'
	})

	if type(data[1]) == 'table' then
		local currentEarnings = (data[1].extradata or {})['earningsin' .. _CURRENT_YEAR]
		return tonumber(currentEarnings or 0) or 0
	end

	return 0
end

function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = Json.parseIfString(args['opponent' .. opponentIndex])
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

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
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
	local winner = tostring(args.winner or '')
	if Logic.readBool(args.finished) then
		local placement = 1
		local lastScore
		local lastPlacement = 1
		-- luacheck: push ignore
		for opponentIndex, opponent in Table.iter.spairs(opponents, p._placementSortFunction) do
			if placement == 1 then
				args.winner = opponentIndex
			end
			if opponent.status == 'S' and opponent.score == lastScore then
				opponent.placement = lastPlacement
			else
				opponent.placement = placement
			end
			args['opponent' .. opponentIndex] = opponent
			placement = placement + 1
			lastScore = opponent.score
			lastPlacement = opponent.placement
		end
	-- luacheck: pop
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			args['opponent' .. opponentIndex] = opponent
		end
	end
	if winner == _RESULT_TYPE_DRAW or winner == '0' then
		args.winner = 0
		args.resulttype = _RESULT_TYPE_DRAW
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
	map.extradata = {
		ot = map.ot,
		otlength = map.otlength,
		comment = map.comment,
		header = map.header,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
	}
	return map
end

function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
				obj.index = scoreIndex
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
				obj.index = scoreIndex
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end
	local isFinished = map.finished
	if not Logic.isEmpty(isFinished) then
		isFinished = Logic.readBool(isFinished)
	else
		isFinished = not Logic.readBool(map.unfinished)
	end
	if isFinished and not Logic.isEmpty(indexedScores) then
		map.winner = mapFunctions.getWinner(indexedScores)
	end

	return map
end

function mapFunctions.getWinner(indexedScores)
	table.sort(indexedScores, mapFunctions.mapWinnerSortFunction)
	return indexedScores[1].index
end

function mapFunctions.mapWinnerSortFunction(op1, op2)
	local op1norm = op1.status == 'S'
	local op2norm = op2.status == 'S'
	if op1norm then
		if op2norm then
			return tonumber(op1.score) > tonumber(op2.score)
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

	-- fill in goals from goal progression
	local scorers = {}
	for g = 1, 1000 do
		local scorer = map['goal' .. g .. 'player']
		if Logic.isEmpty(scorer) then
			break
		elseif scorer:match('op%d_p%d') then
			scorer = scorer:gsub('op', ''):gsub('p', '')
			scorers[scorer] = (scorers[scorer] or 0) + 1
		end
	end
	for scorer, goals in pairs(scorers) do
		participants[scorer] = {
			goals = goals
		}
	end

	-- fill in goals and cars
	-- goals are overwritten if set here
	for o = 1, MAX_NUM_OPPONENTS do
		for player = 1, MAX_NUM_PLAYERS do
			local participant = participants[o .. '_' .. player] or {}
			local opstring = 'opponent' .. o .. '_p' .. player
			local goals = map[opstring .. 'goals']
			local car = map[opstring .. 'car']
			participant.goals = Logic.isEmpty(goals) and participant.goals or goals
			participant.car = Logic.isEmpty(car) and participant.car or car
			if not Table.isEmpty(participant) then
				participants[o .. '_' .. player] = participant
			end
		end
	end

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

--needed for legacy conversion to work for solo brackets
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

return p
