---
-- @Liquipedia
-- wiki=trackmania
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
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local STATUS_HAS_SCORE = 'S'
local STATUS_DEFAULT_WIN = 'W'
local ALLOWED_STATUSES = { STATUS_DEFAULT_WIN, 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20
local RESULT_TYPE_DRAW = 'draw'
local BYE_OPPONENT_NAME = 'bye'
local RESULT_TYPE_WALKOVER = 'default'

local globalVars = PageVariableNamespace()

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match)
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
	if opponent.template:lower() == BYE_OPPONENT_NAME then
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
function CustomMatchGroupInput._placementSortFunction(opponents, opponentKey1, opponentKey2)
	local op1 = opponents[opponentKey1]
	local op2 = opponents[opponentKey2]
	local op1norm = op1.status == STATUS_HAS_SCORE
	local op2norm = op2.status == STATUS_HAS_SCORE
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
		elseif op1.status == STATUS_DEFAULT_WIN then return true
		elseif Table.includes(ALLOWED_STATUSES, op1.status) then return false
		elseif op2.status == STATUS_DEFAULT_WIN then return false
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
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '2v2'))
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

	local casters = {}
	for casterKey, casterName in Table.iter.pairsByPrefix(match, 'caster') do
		table.insert(casters, CustomMatchGroupInput._getCasterInformation(
			casterName,
			match[casterKey .. 'flag'],
			match[casterKey .. 'name']
		))
	end
	table.sort(casters, function(c1, c2) return c1.displayName:lower() < c2.displayName:lower() end)

	local showh2h = Logic.readBool(match.showh2h)
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	match.extradata = {
		showh2h = showh2h,
		casters = Table.isNotEmpty(casters) and Json.stringify(casters) or nil,
	}
	return match
end

function CustomMatchGroupInput._getCasterInformation(name, flag, displayName)
	if String.isEmpty(flag) then
		flag = Variables.varDefault(name .. '_flag')
	end
	if String.isEmpty(displayName) then
		displayName = Variables.varDefault(name .. '_dn')
	end
	if String.isEmpty(flag) or String.isEmpty(displayName) then
		local parent = Variables.varDefault(
			'tournament_parent',
			mw.title.getCurrentTitle().text
		)
		local pageName = mw.ext.TeamLiquidIntegration.resolve_redirect(name)
		local data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			conditions = '[[page::' .. pageName .. ']] AND [[parent::' .. parent .. ']]',
			query = 'flag, id',
			limit = 1,
		})
		if type(data) == 'table' and data[1] then
			flag = String.isNotEmpty(flag) and flag or data[1].flag
			displayName = String.isNotEmpty(displayName) and displayName or data[1].id
		end
	end
	if String.isNotEmpty(flag) then
		Variables.varDefine(name .. '_flag', flag)
	end
	if String.isEmpty(displayName) then
		displayName = name
	end
	if String.isNotEmpty(displayName) then
		Variables.varDefine(name .. '_dn', displayName)
	end
	return {
		name = name,
		displayName = displayName,
		flag = flag,
	}
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

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getTeamIcon(opponent.template)
			end

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = STATUS_HAS_SCORE
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end

			--set Walkover from Opponent status
			args.walkover = args.walkover or STATUS_TO_WALKOVER[opponent.status]

			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				args = matchFunctions.getPlayers(args, opponentIndex, opponent.name)
			end
		end
	end

	--set resulttype to 'default' if walkover is set
	if args.walkover then
		args.resulttype = RESULT_TYPE_WALKOVER
	end

	local autoFinished = Logic.readBool(Logic.emptyOr(args.autofinished, true))
	-- see if match should actually be finished if score is set
	if isScoreSet and autoFinished and not Logic.readBool(args.finished) then
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
		local lastStatus
		-- luacheck: push ignore
		for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
			if opponent.status ~= STATUS_HAS_SCORE and opponent.status ~= STATUS_DEFAULT_WIN and placement == 1 then
				placement = 2
			end
			if placement == 1 then
				args.winner = opponentIndex
			end
			if opponent.status == STATUS_HAS_SCORE and opponent.score == lastScore then
				opponent.placement = lastPlacement
			elseif opponent.status ~= STATUS_HAS_SCORE and opponent.status == lastStatus then
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
		winner == RESULT_TYPE_DRAW or
		winner == '0' or (
			Logic.readBool(args.finished) and
			#opponents == 2 and
			opponents[1].status == STATUS_HAS_SCORE and
			opponents[2].status == STATUS_HAS_SCORE and
			opponents[1].score == opponents[2].score
		)
	then
		args.winner = 0
		args.resulttype = RESULT_TYPE_DRAW
	elseif
		Logic.readBool(args.finished) and
		#opponents == MAX_NUM_OPPONENTS and
		opponents[1].status ~= STATUS_HAS_SCORE and
		opponents[1].status == opponents[2].status
	then
		args.winner = 0
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
	local overtimes = Array.extractValues(Table.mapValues(mw.text.split(map.overtime or '', ','), tonumber))

	map.extradata = {
		comment = map.comment,
		header = map.header,
		overtime = Table.isNotEmpty(overtimes) and Json.stringify(overtimes) or nil
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
				obj.status = STATUS_HAS_SCORE
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
	local op1norm = op1.status == STATUS_HAS_SCORE
	local op2norm = op2.status == STATUS_HAS_SCORE
	if op1norm then
		if op2norm then
			return tonumber(op1.score) > tonumber(op2.score)
		else return true end
	else
		if op2norm then return false
		elseif op1.status == STATUS_DEFAULT_WIN then return true
		elseif Table.includes(ALLOWED_STATUSES, op1.status) then return false
		elseif op2.status == STATUS_DEFAULT_WIN then return false
		elseif Table.includes(ALLOWED_STATUSES, op2.status) then return true
		else return true end
	end
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', '2v2'))
	return MatchGroupInput.getCommonTournamentVars(map)
end

function mapFunctions.getParticipantsData(map)
	local participants = map.participants or {}

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for player = 1, MAX_NUM_PLAYERS do
			local participant = participants[opponentIndex .. '_' .. player] or {}
			if not Table.isEmpty(participant) then
				participants[opponentIndex .. '_' .. player] = participant
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

return CustomMatchGroupInput
