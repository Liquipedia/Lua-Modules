---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local BrawlerNames = mw.loadData('Module:BrawlerNames')

local Opponent = Lua.import('Module:Opponent')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input')

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local NOT_PLAYED = {'skip', 'np'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_VODGAMES = 20
local FIRST_PICK_CONVERSION = {
	blue = 1,
	['1'] = 1,
	red = 2,
	['2'] = 2,
}
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

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
function CustomMatchGroupInput._placementSortFunction(tbl, key1, key2)
	local op1 = tbl[key1]
	local op2 = tbl[key2]
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
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
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
	match.extradata = {
		mvp = MatchGroupInput.readMvp(match),
	}
	return match
end

---@param args table
---@return table
function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false

	local sumscores = {}
	for _, map in Table.iter.pairsByPrefix(args, 'map') do
		if map.winner then
			sumscores[map.winner] = (sumscores[map.winner] or 0) + 1
		end
	end

	local bestof = Logic.emptyOr(args.bestof, Variables.varDefault('bestof', 5))
	bestof = tonumber(bestof) or 5
	Variables.varDefine('bestof', bestof)
	local firstTo = bestof / 2

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, args.timestamp)

			opponent.score = opponent.score or sumscores[opponentIndex]

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
				if firstTo < tonumber(opponent.score) then
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
				args = MatchGroupInput.readPlayersOfTeam(args, opponentIndex, opponent.name)
			end
		end
	end

	--set resulttype to 'default' if walkover is set
	if args.walkover then
		args.resulttype = 'default'
	elseif isScoreSet then
		-- if isScoreSet is true we have scores from at least one opponent
		-- in case the other opponent(s) have no score set manually and
		-- no sumscore set we have to set them to 0 now so they are
		-- not displayed as blank
		for _, opponent in pairs(opponents) do
			if
				String.isEmpty(opponent.status)
				and Logic.isEmpty(opponent.score)
			then
				opponent.score = 0
				opponent.status = 'S'
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(args.finished) then
		local threshold = args.dateexact and 30800 or 86400
		if args.timestamp + threshold < NOW then
			args.finished = true
		end
	end

	if not args.winner then
		matchFunctions._checkDraw(opponents, firstTo, args)
	end

	-- apply placements and winner if finshed
	if Logic.readBool(args.finished) then
		matchFunctions._setPlacementsAndWinner(opponents, args)
	end

	Array.forEach(opponents, function(opponent, opponentIndex)
		args['opponent' .. opponentIndex] = opponent
	end)

	return args
end

---@param opponents table[]
---@param match table
function matchFunctions._setPlacementsAndWinner(opponents, match)
	local counter = 0
	local lastScore
	local lastStatus
	local lastPlacement

	match.winner = tonumber(match.winner)

	for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
		local score = tonumber(opponent.score)
		counter = counter + 1
		if not match.winner then
			match.winner = opponentIndex
		end
		if lastScore == score and lastStatus == opponent.status then
			opponents[opponentIndex].placement = tonumber(opponents[opponentIndex].placement) or lastPlacement
		else
			opponents[opponentIndex].placement = tonumber(opponents[opponentIndex].placement) or counter
			lastPlacement = counter
			lastScore = score or nil
			lastStatus = opponent.status or nil
		end
	end
end

---@param opponents table[]
---@param firstTo number
---@param match table
function matchFunctions._checkDraw(opponents, firstTo, match)
	local finished = Logic.readBool(match.finished)
	local score1 = opponents[1].score
	local status1 = opponents[1].status
	local isDraw = Array.all(opponents, function(opponent)
		return opponent.score == firstTo
			or finished and opponent.score == score1 and opponent.status == status1
	end)

	if not isDraw then return end

	match.winner = 0
	match.finished = true
	match.resulttype = 'draw'
end

--
-- map related functions
--

---@param map table
---@return table
function mapFunctions.getExtraData(map)
	local bestof = Logic.emptyOr(map.bestof, Variables.varDefault('map_bestof', 3))
	bestof = tonumber(bestof) or 3
	Variables.varDefine('map_bestof', bestof)
	map.extradata = {
		bestof = bestof,
		comment = map.comment,
		header = map.header,
		maptype = map.maptype,
		firstpick = FIRST_PICK_CONVERSION[string.lower(map.firstpick or '')]
	}

	local bans = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, BrawlerNames)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		bans['team' .. opponentIndex] = {}
		for _, ban in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			ban = getCharacterName(ban)
			table.insert(bans['team' .. opponentIndex], ban)
		end
	end

	map.extradata.bans = Json.stringify(bans)
	map.bestof = bestof

	return map
end

---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	map.score1 = tonumber(map.score1 or '')
	map.score2 = tonumber(map.score2 or '')
	map.scores = { map.score1, map.score2 }
	if Table.includes(NOT_PLAYED, string.lower(map.winner or '')) then
		map.winner = 0
		map.resulttype = 'np'
	elseif Logic.isNumeric(map.winner) then
		map.winner = tonumber(map.winner)
	end
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

---@param map table
---@return table
function mapFunctions.getParticipantsData(map)
	local participants = {}
	local maximumPickIndex = 0
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, BrawlerNames)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for _, player, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
			participants[opponentIndex .. '_' .. playerIndex] = {player = player}
		end

		for _, brawler, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'c') do
			participants[opponentIndex .. '_' .. pickIndex] = participants[opponentIndex .. '_' .. pickIndex] or {}
			participants[opponentIndex .. '_' .. pickIndex].brawler = getCharacterName(brawler)
			if maximumPickIndex < pickIndex then
				maximumPickIndex = pickIndex
			end
		end
	end

	map.extradata.maximumpickindex = maximumPickIndex
	map.participants = participants
	return map
end

return CustomMatchGroupInput
