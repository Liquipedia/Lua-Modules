---
-- @Liquipedia
-- wiki=runeterra
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

TODO:
- is bestof for each game a thing?
- should default bestofs be set?
- add support for team matches -> need feedback from the wiki
- is it necessary to list additional decks on top of the banned and played (per game) ones?

]]--

local p = require('Module:Brkts/WikiSpecific/Base')

local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Template = require('Module:Template')
local json = require('Module:Json')
local _frame

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20
local MAX_NUM_MAPS = 7

-- containers for process helper functions
local matchFunctions = {}
local gameFunctions = {}
local opponentFunctions = {}

-- called from Module:MatchGroup
function p.processMatch(frame, match)
	_frame = frame
	if type(match) == 'string' then
		match = json.parse(match)
	end

	-- process match
	match = matchFunctions.getDateStuff(match)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getLinks(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function p.processMap(frame, game)
	_frame = frame
	if type(game) == 'string' then
		game = json.parse(game)
	end

	-- process game
	game = gameFunctions.getExtraData(game)
	game = gameFunctions.getScoresAndWinner(game)
	game = gameFunctions.getTournamentVars(game)
	game = gameFunctions.getParticipantsData(game)

	return game
end

-- called from Module:Match/Subobjects
function p.processOpponent(frame, opponent)
	_frame = frame
	if type(opponent) == 'string' then
		opponent = json.parse(opponent)
	end

	-- process opponent
	if not Logic.isEmpty(opponent.template) and
		string.lower(opponent.template) == 'bye' then
			opponent.name = 'BYE'
			opponent.type = 'literal'
	end

	return opponent
end

-- called from Module:Match/Subobjects
function p.processPlayer(frame, player)
	_frame = frame
	if type(player) == 'string' then
		player = json.parse(player)
	end
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
	local extradata = json.parseIfString(opp.extradata or '{}')
	local set1win = extradata.set1win and 1 or 0
	local set2win = extradata.set2win and 1 or 0
	local set3win = extradata.set3win and 1 or 0
	local sum = set1win + set2win + set3win
	return sum
end

--
-- match related functions
--
function matchFunctions.getDateStuff(match)
	local lang = mw.getContentLanguage()
	-- parse date string with abbr
	if not Logic.isEmpty(match.date) then
		local matchString = match.date or ''
		local timezone = String.split(
			String.split(matchString, 'data%-tz%="')[2] or '',
			'"')[1] or String.split(
			String.split(matchString, 'data%-tz%=\'')[2] or '',
			'\'')[1] or ''
		local matchDate = String.explode(matchString, '<', 0):gsub('-', '')
		match.date = matchDate .. timezone
		match.dateexact = String.contains(match.date, '%+') or String.contains(match.date, '%-')
	else
		match.date = lang:formatDate(
			'c',
			(Variables.varDefault('tournament_enddate', '') or '')
				.. ' + ' .. Variables.varDefault('num_missing_dates', '0') .. ' second'
		)
		match.dateexact = false
		Variables.varDefine('num_missing_dates', Variables.varDefault('num_missing_dates', 0) + 1)
	end
	return match
end

function matchFunctions.getLinks(match)
	match.links = json.stringify({
		preview = match.preview,
		preview2 = match.preview2,
		interview = match.interview,
		interview2 = match.interview2,
		review = match.review,
		recap = match.recap,
		lrthread = match.lrthread,
	})
	return match
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '1v1'))
	match.type = Logic.emptyOr(match.type, Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_ticker_name'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
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
	match.stream = json.stringify({
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
	})
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	-- apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if not Logic.isEmpty(vodgame) then
			local game = Logic.emptyOr(match['game' .. index], nil, {})
			if type(game) == 'string' then
				game = json.parse(game)
			end
			game.vod = game.vod or vodgame
			match['game' .. index] = game
		end
	end
	return match
end

function matchFunctions.getExtraData(match)
	local extradata = {
		matchsection = Variables.varDefault('matchsection'),
		comment = match.comment,
	}
	local index = 1
	while (not String.isEmpty(match['ban' .. index])) do
		extradata['ban' .. index] = match['ban' .. index]
		extradata['ban' .. index .. 'opponent'] = match['ban' .. index .. 'opponent']
	end
	match.extradata = json.stringify(extradata)
	return match
end

function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false

	local sumscores = {}
	for gameIndex = 1, MAX_NUM_MAPS do
		if not args['game' .. gameIndex] then
			break
		end
		local game = json.parseIfString(args['game' .. gameIndex])
		sumscores[game.winner] = (sumscores[game.winner] or 0) + 1
	end

	local bestof = args.bestof or Variables.varDefault('bestof', '')
	bestof = tonumber(bestof) or 0
	local firstTo = math.ceil(bestof / 2)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			if type(opponent) == 'string' then
				opponent = json.parse(opponent)
			end

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
				if firstTo > 0 and firstTo <= tonumber(opponent.score) then
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
		for opponentIndex, opponent in Table.iter.spairs(opponents, p._placementSortFunction) do
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
		local player = match['opponent' .. opponentIndex .. '_p' .. playerIndex] or {}
		if type(player) == 'string' then
			player = json.parse(player)
		end
		player.name = player.name or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		if not Table.isEmpty(player) then
			match['opponent' .. opponentIndex .. '_p' .. playerIndex] = player
		end
	end
	return match
end

--
-- game related functions
--
function gameFunctions.getExtraData(game)
	local bestof = tonumber(game.bestof or 3) or 3
	game.extradata = json.stringify({
		bestof = bestof,
		comment = game.comment,
		header = game.header,
	})
	game.bestof = bestof
	return game
end

function gameFunctions.getScoresAndWinner(game)
	game.score1 = tonumber(game.score1 or '')
	game.score2 = tonumber(game.score2 or '')
	game.scores = { game.score1, game.score2 }
	local firstTo = math.ceil( game.bestof / 2 )
	if (game.score1 or 0) >= firstTo then
		game.winner = 1
		game.finished = true
	elseif (game.score2 or 0) >= firstTo then
		game.winner = 2
		game.finished = true
	end

	return game
end

function gameFunctions.getTournamentVars(game)
	game.mode = Logic.emptyOr(game.mode, Variables.varDefault('tournament_mode', '1v1'))
	game.type = Logic.emptyOr(game.type, Variables.varDefault('tournament_type'))
	game.tournament = Logic.emptyOr(game.tournament, Variables.varDefault('tournament_name'))
	game.tickername = Logic.emptyOr(game.tickername, Variables.varDefault('tournament_ticker_name'))
	game.shortname = Logic.emptyOr(game.shortname, Variables.varDefault('tournament_shortname'))
	game.series = Logic.emptyOr(game.series, Variables.varDefault('tournament_series'))
	game.icon = Logic.emptyOr(game.icon, Variables.varDefault('tournament_icon'))
	game.liquipediatier = Logic.emptyOr(game.liquipediatier, Variables.varDefault('tournament_tier'))
	return game
end

function gameFunctions.getParticipantsData(game)
	local participants = game.participants or {}
	if type(participants) == 'string' then
		participants = json.parse(participants)
	end

	--set the decks played
	if game.mode == '1v1' then
		participants['1_1'] = participants['1_1'] or {}
		participants['1_1'].deck = game.p1deck or game.deck1
		participants['2_1'] = participants['2_1'] or {}
		participants['2_1'].deck = game.p2deck or game.deck2
	elseif game.mode == 'team' then
		--do team participants processing here
	end

	game.participants = participants
	return game
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
	opponent.match2players = '[' .. json.stringify({
		name = opponent.name,
		displayname = opponent.displayname or opponent.name,
		flag = opponent.flag
	}) .. ']'
	opponent.name = nil
	return opponent
end

return p
