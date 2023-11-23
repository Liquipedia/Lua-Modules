---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Array = require('Module:Array')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local getIconName = require('Module:IconName').luaGet
local Streams = require('Module:Links/Stream')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local _STATUS_HAS_SCORE = 'S'
local _STATUS_DEFAULT_WIN = 'W'
local ALLOWED_STATUSES = { _STATUS_DEFAULT_WIN, 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20
local _RESULT_TYPE_DRAW = 'draw'
local _EARNINGS_LIMIT_FOR_FEATURED = 10000
local _CURRENT_YEAR = os.date('%Y')

local globalVars = PageVariableNamespace()

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
	Table.mergeInto(
		match,
		matchFunctions.readDate(match)
	)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)
	match = matchFunctions.getLinks(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)
	map = mapFunctions.getParticipantsData(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	Opponent.resolve(opponent, date)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)

	--score2 & score3 support for every match
	local score2 = tonumber(record.score2 or '')
	local score3 = tonumber(record.score3 or '')
	if score2 then
		record.extradata = {
			score2 = score2,
			score3 = score3,
			set1win = Logic.readBool(record.set1win),
			set2win = Logic.readBool(record.set2win),
			set3win = Logic.readBool(record.set3win),
			additionalScores = true
		}
	end
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
--
-- function to sort out winner/placements
function CustomMatchGroupInput._placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == _STATUS_HAS_SCORE
	local op2norm = op2.status == _STATUS_HAS_SCORE
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
		elseif op1.status == _STATUS_DEFAULT_WIN then return true
		elseif Table.includes(ALLOWED_STATUSES, op1.status) then return false
		elseif op2.status == _STATUS_DEFAULT_WIN then return false
		elseif Table.includes(ALLOWED_STATUSES, op2.status) then return true
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
		or {
			date = MatchGroupInput.getInexactDate(globalVars:get('tournament_enddate')),
			dateexact = false,
		}
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '3v3'))
	match.showh2h = Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
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

	local showh2h = Logic.readBool(match.showh2h)
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	match.extradata = {
		team1icon = getIconName(opponent1.template or ''),
		team2icon = getIconName(opponent2.template or ''),
		lastgame = Variables.varDefault('last_game'),
		isconverted = 0,
		showh2h = showh2h,
		isfeatured = matchFunctions.isFeatured(match),
		casters = MatchGroupInput.readCasters(match),
		hasopponent1 = matchFunctions._checkForNonEmptyOpponent(opponent1),
		hasopponent2 = matchFunctions._checkForNonEmptyOpponent(opponent2),
		liquipediatiertype2 = Variables.varDefault('tournament_tiertype2'),
	}
	return match
end

function matchFunctions._checkForNonEmptyOpponent(opponent)
	if Opponent.typeIsParty(opponent.type) then
		return Array.any(opponent.match2players, function(player) return Logic.isNotEmpty(player.name) end)
	elseif opponent.type == Opponent.team then
		return Logic.isNotEmpty(opponent.template)
	end

	-- Literal case
	return false
end

function matchFunctions.getLinks(match)
	match.links = {}

	-- Shift (formerly Octane)
	for key, shift in Table.iter.pairsByPrefix(match, 'shift', {requireIndex = false}) do
		match.links[key] = 'https://www.shiftrle.gg/matches/' .. shift
	end

	-- Ballchasing
	for key, ballchasing in Table.iter.pairsByPrefix(match, 'ballchasing', {requireIndex = false}) do
		match.links[key] = 'https://ballchasing.com/group/' .. ballchasing
	end

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
		or Logic.readBool(Variables.varDefault('tournament_rlcs_premier'))
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
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, args.date)

			-- Retrieve icon and legacy name for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getTeamIcon(opponent.template)
				if not opponent.icon then
					opponent.icon, opponent.icondark = opponentFunctions.getLegacyTeamIcon(opponent.template)
				end
				opponent.name = opponent.name or opponentFunctions.getLegacyTeamName(opponent.template)
			end

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = _STATUS_HAS_SCORE
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
				args = MatchGroupInput.readPlayersOfTeam(args, opponentIndex, opponent.name)
			end
		end
	end

	--set resulttype to 'default' if walkover is set
	if args.walkover then
		args.resulttype = 'default'
	end

	local autofinished = String.isNotEmpty(args.autofinished) and args.autofinished or true
	-- see if match should actually be finished if score is set
	if isScoreSet and Logic.readBool(autofinished) and not Logic.readBool(args.finished) then
		local currentUnixTime = os.time(os.date('!*t') --[[@as osdateparam]])
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
		local lastStatus
		-- luacheck: push ignore
		for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
			if opponent.status ~= _STATUS_HAS_SCORE and opponent.status ~= _STATUS_DEFAULT_WIN and placement == 1 then
				placement = 2
			end
			if placement == 1 then
				args.winner = opponentIndex
			end
			if opponent.status == _STATUS_HAS_SCORE and opponent.score == lastScore then
				opponent.placement = lastPlacement
			elseif opponent.status ~= _STATUS_HAS_SCORE and opponent.status == lastStatus then
				opponent.placement = lastPlacement
			else
				opponent.placement = placement
			end
			args['opponent' .. opponentIndex] = opponent
			placement = placement + 1
			lastScore = opponent.score
			lastPlacement = opponent.placement
			lastStatus = opponent.status
		end
	-- luacheck: pop
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			args['opponent' .. opponentIndex] = opponent
		end
	end
	if
		winner == _RESULT_TYPE_DRAW or
		winner == '0' or (
			Logic.readBool(args.finished) and
			#opponents == 2 and
			opponents[1].status == _STATUS_HAS_SCORE and
			opponents[2].status == _STATUS_HAS_SCORE and
			opponents[1].score == opponents[2].score
		)
	then
		args.winner = 0
		args.resulttype = _RESULT_TYPE_DRAW
	elseif
		Logic.readBool(args.finished) and
		#opponents == 2 and
		opponents[1].status ~= _STATUS_HAS_SCORE and
		opponents[1].status == opponents[2].status
	then
		args.winner = 0
	end
	return args
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)
	local timeouts = Array.extractValues(Table.mapValues(mw.text.split(map.timeout or '', ','), tonumber))

	map.extradata = {
		ot = map.ot,
		otlength = map.otlength,
		comment = map.comment,
		header = map.header,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
		timeout = Table.isNotEmpty(timeouts) and Json.stringify(timeouts) or nil
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
				score = tonumber(score)
				obj.status = _STATUS_HAS_SCORE
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
	local op1norm = op1.status == _STATUS_HAS_SCORE
	local op2norm = op2.status == _STATUS_HAS_SCORE
	if op1norm then
		if op2norm then
			return tonumber(op1.score) > tonumber(op2.score)
		else return true end
	else
		if op2norm then return false
		elseif op1.status == _STATUS_DEFAULT_WIN then return true
		elseif Table.includes(ALLOWED_STATUSES, op1.status) then return false
		elseif op2.status == _STATUS_DEFAULT_WIN then return false
		elseif Table.includes(ALLOWED_STATUSES, op2.status) then return true
		else return true end
	end
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', '3v3'))
	return MatchGroupInput.getCommonTournamentVars(map)
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
function opponentFunctions.getTeamIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

--the following 2 functions are a fallback
--they are only useful if the team template doesn't exist
--in the team template extension
function opponentFunctions.getLegacyTeamName(template)
	local team = Template.expandTemplate(mw.getCurrentFrame(), 'Team', { template })
	team = team:gsub('%&', '')
	team = String.split(team, 'link=')[2]
	team = String.split(team, ']]')[1]
	return team
end

function opponentFunctions.getLegacyTeamIcon(template)
	local iconTemplate = Template.expandTemplate(mw.getCurrentFrame(), 'Team', { template })
	iconTemplate = iconTemplate:gsub('%&', '')
	local icon = String.split(iconTemplate, 'File:')[2]
	local iconDark = String.split(iconTemplate, 'File:')[3] or icon
	icon = String.split(icon, '|')[1]
	iconDark = String.split(iconDark, '|')[1]
	return icon, iconDark
end

return CustomMatchGroupInput
