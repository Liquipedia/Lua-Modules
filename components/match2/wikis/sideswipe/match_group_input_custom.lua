---
-- @Liquipedia
-- wiki=sideswipe
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local STATUS_HAS_SCORE = 'S'
local STATUS_DEFAULT_WIN = 'W'
local ALLOWED_STATUSES = { STATUS_DEFAULT_WIN, 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local RESULT_TYPE_DRAW = 'draw'
local EARNINGS_LIMIT_FOR_FEATURED = 10000
local CURRENT_YEAR = os.date('%Y')
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
	map = mapFunctions.getParticipantsData(map)

	return map
end

-- called from Module:Match/Subobjects
---@param record table
---@param timestamp integer
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
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
end

--
--
-- function to sort out winner/placements
---@param tbl table[]
---@param key1 integer
---@param key2 integer
---@return boolean
function matchFunctions._placementSortFunction(tbl, key1, key2)
	local op1 = tbl[key1]
	local op2 = tbl[key2]
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
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		isfeatured = matchFunctions.isFeatured(match)
	}
	return match
end

---@param match table
---@return boolean
function matchFunctions.isFeatured(match)
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	if opponent1.type ~= 'team' or opponent2.type ~= 'team' then
		return false
	end

	if
		tonumber(match.liquipediatier or '') == 1
		or tonumber(match.liquipediatier or '') == 2
		or not String.isEmpty(Variables.varDefault('match_featured_override'))
	then
		return true
	end

	if matchFunctions.currentEarnings(opponent1.name) >= EARNINGS_LIMIT_FOR_FEATURED or
		matchFunctions.currentEarnings(opponent2.name) >= EARNINGS_LIMIT_FOR_FEATURED then
		return true
	end
	return false
end

---@param name string?
---@return integer
function matchFunctions.currentEarnings(name)
	if String.isEmpty(name) then
		return 0
	end
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[name::' .. name .. ']]',
		query = 'extradata'
	})

	if type(data[1]) == 'table' then
		local currentEarnings = (data[1].extradata or {})['earningsin' .. CURRENT_YEAR]
		return tonumber(currentEarnings or 0) or 0
	end

	return 0
end

---@param args table
---@return table
function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, args.timestamp)

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
		local threshold = args.dateexact and 30800 or 86400
		if args.timestamp + threshold < NOW then
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
		for opponentIndex, opponent in Table.iter.spairs(opponents, matchFunctions._placementSortFunction) do
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
	if winner == RESULT_TYPE_DRAW
	then args.resulttype = RESULT_TYPE_DRAW
	end
	return args
end

--
-- map related functions
--

---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		ot = map.ot,
		otlength = map.otlength,
		comment = map.comment,
		header = map.header,
		t1goals = map.t1goals,
		t2goals = map.t2goals,
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

---@param map table
---@return table
function mapFunctions.getParticipantsData(map)
	local participants = map.participants or {}

	-- fill in goals from goal progression
	local scorers = {}
	for goalIndex = 1, 1000 do
		local scorer = map['goal' .. goalIndex .. 'player']
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
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for player = 1, MAX_NUM_PLAYERS do
			local participant = participants[opponentIndex .. '_' .. player] or {}
			local opstring = 'opponent' .. opponentIndex .. '_p' .. player
			local goals = map[opstring .. 'goals']
			local car = map[opstring .. 'car']
			participant.goals = Logic.isEmpty(goals) and participant.goals or goals
			participant.car = Logic.isEmpty(car) and participant.car or car
			if not Table.isEmpty(participant) then
				participants[opponentIndex .. '_' .. player] = participant
			end
		end
	end

	map.participants = participants
	return map
end

return CustomMatchGroupInput
