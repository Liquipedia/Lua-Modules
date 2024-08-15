---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

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
	match = matchFunctions.getLinks(match)

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

-- function to sort out winner/placements
---@param tbl table[]
---@param key1 integer
---@param key2 integer
---@return boolean
function CustomMatchGroupInput._placementSortFunction(tbl, key1, key2)
	local op1 = tbl[key1]
	local op2 = tbl[key2]
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

---@param opp table
---@return integer
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

---@param matchArgs table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function matchFunctions.readDate(matchArgs)
	return MatchGroupInput.readDate(matchArgs.date, {'tournament_enddate'})
end

---@param match table
---@return table
function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '3v3'))
	match.showh2h = Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
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

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	local opponent1 = match.opponent1 or {}
	local opponent2 = match.opponent2 or {}

	local showh2h = Logic.readBool(match.showh2h)
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	match.extradata = {
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

---@param opponent table
---@return boolean
function matchFunctions._checkForNonEmptyOpponent(opponent)
	if Opponent.typeIsParty(opponent.type) then
		return Array.any(opponent.match2players, function(player) return Logic.isNotEmpty(player.name) end)
	elseif opponent.type == Opponent.team then
		return Logic.isNotEmpty(opponent.template)
	end

	-- Literal case
	return false
end

---@param match table
---@return table
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

---@param name string?
---@return integer
function matchFunctions.currentEarnings(name)
	if String.isEmpty(name) then
		return 0
	end
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[name::' .. name .. ']]',
		query = 'extradata'
	})[1]

	if type(data) == 'table' then
		local currentEarnings = (data.extradata or {})['earningsin' .. _CURRENT_YEAR]
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

---@param map table
---@return table
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

---@param map table
---@return table
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

return CustomMatchGroupInput
