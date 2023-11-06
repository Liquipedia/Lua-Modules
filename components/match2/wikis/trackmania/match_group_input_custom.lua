---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
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
local RESULT_TYPE_DRAW = 'draw'
local BYE_OPPONENT_NAME = 'bye'
local RESULT_TYPE_WALKOVER = 'default'
local WINNER_FIRST_OPPONENT = '0'

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

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if (opponent.template or ''):lower() == BYE_OPPONENT_NAME then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	Opponent.resolve(opponent, date)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)

	--score2 & score3 support for every match
	local score2 = tonumber(record.score2)
	local score3 = tonumber(record.score3)
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

function CustomMatchGroupInput._sortOpponents(op1, op2, op1norm, op2norm)
	if op1norm then return true
	elseif op2norm then return false
	elseif op1.status == STATUS_DEFAULT_WIN then return true
	elseif Table.includes(ALLOWED_STATUSES, op1.status) then return false
	elseif op2.status == STATUS_DEFAULT_WIN then return false
	elseif Table.includes(ALLOWED_STATUSES, op2.status) then return true
	else return true
	end
end

--
--
-- function to sort out winner/placements
function CustomMatchGroupInput._placementSortFunction(opponents, opponentKey1, opponentKey2)
	local op1 = opponents[opponentKey1]
	local op2 = opponents[opponentKey2]
	local op1norm = op1.status == STATUS_HAS_SCORE
	local op2norm = op2.status == STATUS_HAS_SCORE
	if op1norm and op2norm then
		local op1setwins = CustomMatchGroupInput._getSetWins(op1)
		local op2setwins = CustomMatchGroupInput._getSetWins(op2)
		if op1setwins + op2setwins > 0 then
			return op1setwins > op2setwins
		else
			return tonumber(op1.score) > tonumber(op2.score)
		end
	else return CustomMatchGroupInput._sortOpponents(op1, op2, op1norm, op2norm) end
end

function CustomMatchGroupInput._getSetWins(opp)
	local extradata = opp.extradata or {}
	local set1win = extradata.set1win and 1 or 0
	local set2win = extradata.set2win and 1 or 0
	local set3win = extradata.set3win and 1 or 0
	return set1win + set2win + set3win
end

--
-- match related functions
--
function matchFunctions.readDate(matchArgs)
	return matchArgs.date
		and MatchGroupInput.readDate(matchArgs.date)
		or {
			date = MatchGroupInput.getInexactDate(Variables.varDefault('tournament_enddate')),
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

	return match
end

function matchFunctions.isFeatured(match)
	return tonumber(match.liquipediatier) == 1
		or tonumber(match.liquipediatier) == 2
end

function matchFunctions.getExtraData(match)
	local opponent1 = match.opponent1 or {}
	local opponent2 = match.opponent2 or {}

	local showh2h = Logic.readBool(match.showh2h)
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	match.extradata = {
		showh2h = showh2h,
		isfeatured = matchFunctions.isFeatured(match),
		casters = MatchGroupInput.readCasters(match),
		hasopponent1 = Logic.isNotEmpty(opponent1.name) and opponent1.type ~= Opponent.literal,
		hasopponent2 = Logic.isNotEmpty(opponent2.name) and opponent2.type ~= Opponent.literal,
	}
	return match
end

function matchFunctions.readOpponents(match)
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.date)

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
			match.walkover = match.walkover or STATUS_TO_WALKOVER[opponent.status]

			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name)
			end
		end
	end

	return opponents, isScoreSet, match
end

function matchFunctions.applyMatchPlacement(opponents, match)
	local placement = 1
	local lastScore
	local lastPlacement = 1
	local lastStatus
	for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
		if opponent.status ~= STATUS_HAS_SCORE and opponent.status ~= STATUS_DEFAULT_WIN and placement == 1 then
			placement = 2
		elseif placement == 1 then
			match.winner = opponentIndex
		end
		if opponent.status == STATUS_HAS_SCORE and opponent.score == lastScore then
			opponent.placement = lastPlacement
		elseif opponent.status ~= STATUS_HAS_SCORE and opponent.status == lastStatus then
			opponent.placement = lastPlacement
		else
			opponent.placement = placement
		end
		match['opponent' .. opponentIndex] = opponent
		placement = placement + 1
		lastScore = opponent.score
		lastPlacement = opponent.placement
		lastStatus = opponent.status
	end

	return match
end

function matchFunctions.setMatchWinner(winner, opponents, match)
	if
		winner == RESULT_TYPE_DRAW or
		winner == WINNER_FIRST_OPPONENT or (
			Logic.readBool(match.finished) and
			#opponents == MAX_NUM_OPPONENTS and
			opponents[1].status == STATUS_HAS_SCORE and
			opponents[2].status == STATUS_HAS_SCORE and
			opponents[1].score == opponents[2].score
		)
	then
		match.winner = tonumber(WINNER_FIRST_OPPONENT)
		match.resulttype = RESULT_TYPE_DRAW
	elseif
		Logic.readBool(match.finished) and
		#opponents == MAX_NUM_OPPONENTS and
		opponents[1].status ~= STATUS_HAS_SCORE and
		opponents[1].status == opponents[2].status
	then
		match.winner = tonumber(WINNER_FIRST_OPPONENT)
	end

	return match
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents
	local isScoreSet
	opponents, isScoreSet, match = matchFunctions.readOpponents(match)

	--set resulttype to 'default' if walkover is set
	if match.walkover then
		match.resulttype = RESULT_TYPE_WALKOVER
	end

	local autoFinished = Logic.readBool(Logic.emptyOr(match.autofinished, true))
	-- see if match should actually be finished if score is set
	if isScoreSet and autoFinished and not Logic.readBool(match.finished) then
		local currentUnixTime = os.time(os.date('!*t') --[[@as osdateparam]])
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', match.date))
		local threshold = match.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	local winner = tostring(match.winner or '')
	if Logic.readBool(match.finished) then
		match = matchFunctions.applyMatchPlacement(opponents, match)
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			match['opponent' .. opponentIndex] = opponent
		end
	end

	-- set the match winner
	match = matchFunctions.setMatchWinner(winner, opponents, match)
	return match
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)

	map.extradata = {
		comment = map.comment,
		header = map.header,
		overtime = Logic.readBool(map.overtime)
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
	if not Logic.isEmpty(indexedScores) then
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
	if op1norm and op2norm then
		return tonumber(op1.score) > tonumber(op2.score)
	else return CustomMatchGroupInput._sortOpponents(op1, op2, op1norm, op2norm) end
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', '2v2'))
	return MatchGroupInput.getCommonTournamentVars(map)
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
