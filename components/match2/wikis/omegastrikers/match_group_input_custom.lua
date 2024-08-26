---
-- @Liquipedia
-- wiki=omegastrikers
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
local StrikerNames = mw.loadData('Module:StrikerNames')

local Opponent = Lua.import('Module:Opponent')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L', 'D'}
local STATUS_TO_WALKOVER = {FF = 'ff', DQ = 'dq', L = 'l'}
local NOT_PLAYED = {'skip', 'np'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
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

	CustomMatchGroupInput._underScoreAdjusts(match)

	return match
end

---@param match table
function CustomMatchGroupInput._underScoreAdjusts(match)
	local fixUnderscore = function(page)
		return page and page:gsub(' ', '_') or page
	end

	for opponentKey, opponent in Table.iter.pairsByPrefix(match, 'opponent') do
		opponent.name = fixUnderscore(opponent.name)

		for _, player in Table.iter.pairsByPrefix(match, opponentKey .. '_p') do
			player.name = fixUnderscore(player.name)
		end
	end
end

-- called from Module:Match/Subobjects
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	local bestof = tonumber(Logic.emptyOr(map.bestof, Variables.varDefault('map_bestof'))) or 3
	Variables.varDefine('map_bestof', bestof)
	map.bestof = bestof

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
	if op1norm and op2norm then return tonumber(op1.score) > tonumber(op2.score)
	elseif not op2norm then return true
	elseif not op1norm then return false
	elseif op1.status == 'W' then return true
	elseif op1.status == 'DQ' then return false
	elseif op2.status == 'W' then return false
	elseif op2.status == 'DQ' then return true
	else return true
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
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

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
	local firstTo = math.ceil(bestof / 2)

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

	opponents = Array.map(opponents, function(opponent)
		opponent.score = tonumber(opponent.score)
		return opponent
	end)

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

	-- apply placements and winner if finshed
	if Logic.readBool(args.finished) then
		if #opponents == 2 and opponents[1].score == opponents[2].score and opponents[1].score == firstTo then
			args.winner = tonumber(args.winner) or 0
		end

		local currentPlacement = 1
		local placement = 1
		local lastOpponentScore, lastOpponentStatus
		for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
			if lastOpponentStatus ~= opponent.status or lastOpponentScore ~= opponent.score then
				lastOpponentStatus = opponent.status
				lastOpponentScore = opponent.score
				currentPlacement = placement
			end


			if currentPlacement == 1 then
				args.winner = tonumber(args.winner) or opponentIndex
			end
			opponent.placement = currentPlacement
			args['opponent' .. opponentIndex] = opponent
			placement = placement + 1
		end
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			args['opponent' .. opponentIndex] = opponent
		end
	end

	if args.winner == 0 then
		args.resulttype = args.resulttype or 'draw'
	end

	return args
end

---@param match table
---@param opponentIndex integer
---@param teamName string
---@return table
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

---@param map table
---@return table
function mapFunctions.getExtraData(map)
	local bans = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, StrikerNames)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		bans['team' .. opponentIndex] = {}
		for _, ban in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			table.insert(bans['team' .. opponentIndex], getCharacterName(ban))
		end
	end

	map.extradata = {
		comment = map.comment,
		bans = Json.stringify(bans)
	}

	return map
end

---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	map.score1 = tonumber(map.score1)
	map.score2 = tonumber(map.score2)
	map.scores = { map.score1, map.score2 }
	if Table.includes(NOT_PLAYED, string.lower(map.winner or '')) then
		map.winner = 0
		map.resulttype = 'np'
	elseif Logic.isNumeric(map.winner) then
		map.winner = tonumber(map.winner)
	end
	local firstTo = math.ceil(map.bestof / 2)
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
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, StrikerNames)
	local maximumPickIndex = 0
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for _, player, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
			participants[opponentIndex .. '_' .. playerIndex] = {player = player}
		end

		for _, striker, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'c') do
			participants[opponentIndex .. '_' .. pickIndex] = participants[opponentIndex .. '_' .. pickIndex] or {}
			participants[opponentIndex .. '_' .. pickIndex].striker = getCharacterName(striker)
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
