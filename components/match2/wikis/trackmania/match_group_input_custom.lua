---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local STATUS_HAS_SCORE = 'S'
local STATUS_DEFAULT_WIN = 'W'
local ALLOWED_STATUSES = { STATUS_DEFAULT_WIN, 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local RESULT_TYPE_DRAW = 'draw'
local BYE_OPPONENT_NAME = 'bye'
local RESULT_TYPE_WALKOVER = 'default'
local WINNER_FIRST_OPPONENT = '0'
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
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
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)

	return map
end

---@param record table
---@param timestamp integer
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if (opponent.template or ''):lower() == BYE_OPPONENT_NAME then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type number|string
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)
	end

	Opponent.resolve(opponent, teamTemplateDate)
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

---@param op1 table
---@param op2 table
---@param op1norm boolean
---@param op2norm boolean
---@return boolean
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
---@param opponents table[]
---@param opponentKey1 integer
---@param opponentKey2 integer
---@return boolean
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

---@param opp table
---@return integer
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

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function matchFunctions.readDate(matchArgs)
	return MatchGroupInput.readDate(matchArgs.date, {'tournament_enddate'})
end

---@param match table
---@return table
function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '2v2'))
	match.showh2h = Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	return match
end

---@param match table
---@return boolean
function matchFunctions.isFeatured(match)
	return tonumber(match.liquipediatier) == 1
		or tonumber(match.liquipediatier) == 2
end

---@param match table
---@return table
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

---@param match table
---@return table[]
---@return boolean
---@return table
function matchFunctions.readOpponents(match)
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

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

---@param opponents table[]
---@param match table
---@return table
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

---@param winner string|integer?
---@param opponents table[]
---@param match table
---@return table
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

---@param match table
---@return table
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
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
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

---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		header = map.header,
		overtime = Logic.readBool(map.overtime)
	}
	return map
end

---@param map table
---@return table
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

---@param indexedScores table[]
---@return integer?
function mapFunctions.getWinner(indexedScores)
	table.sort(indexedScores, mapFunctions.mapWinnerSortFunction)
	return indexedScores[1].index
end

---@param op1 table
---@param op2 table
---@return boolean
function mapFunctions.mapWinnerSortFunction(op1, op2)
	local op1norm = op1.status == STATUS_HAS_SCORE
	local op2norm = op2.status == STATUS_HAS_SCORE
	if op1norm and op2norm then
		return tonumber(op1.score) > tonumber(op2.score)
	else return CustomMatchGroupInput._sortOpponents(op1, op2, op1norm, op2norm) end
end

return CustomMatchGroupInput
