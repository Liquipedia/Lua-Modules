---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local MathUtil = require('Module:MathUtil')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local Opponent = Lua.import('Module:Opponent')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')

local SIDE_DEF = 'ct'
local SIDE_ATK = 't'
local STATUS_SCORE = 'S'
local STATUS_DRAW = 'D'
local STATUS_DEFAULT_WIN = 'W'
local STATUS_FORFEIT = 'FF'
local STATUS_DISQUALIFIED = 'DQ'
local STATUS_DEFAULT_LOSS = 'L'
local ALLOWED_STATUSES = {
	STATUS_DRAW,
	STATUS_DEFAULT_WIN,
	STATUS_FORFEIT,
	STATUS_DISQUALIFIED,
	STATUS_DEFAULT_LOSS,
}
local NOT_PLAYED_MATCH_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local NOT_PLAYED_RESULT_TYPE = 'np'
local DRAW_RESULT_TYPE = 'draw'
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])
local NOT_PLAYED_SCORE = -1
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local DEFAULT_RESULT_TYPE = 'default'
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.removeUnsetMaps(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getOpponents(match)
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

-- function to check for draws
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckDraw(tbl)
	if #tbl < MAX_NUM_OPPONENTS then
		return false
	end

	return MatchGroupInput.isDraw(tbl)
end

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	local winner = tonumber(data.winner)
	if Logic.readBool(data.finished) then
		if CustomMatchGroupInput.placementCheckDraw(indexedScores) then
			data.winner = 0
			data.resulttype = DRAW_RESULT_TYPE
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = MatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = DEFAULT_RESULT_TYPE
			if MatchGroupInput.hasForfeit(indexedScores) then
				data.walkover = STATUS_FORFEIT
			elseif MatchGroupInput.hasDisqualified(indexedScores) then
				data.walkover = STATUS_DISQUALIFIED
			elseif MatchGroupInput.hasDefaultWinLoss(indexedScores) then
				data.walkover = STATUS_DEFAULT_LOSS
			end
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		elseif CustomMatchGroupInput.placementCheckScoresSet(indexedScores) then
			--C-OPS only has exactly 2 opponents, neither more or less
			if #indexedScores == MAX_NUM_OPPONENTS then
				if tonumber(indexedScores[1].score) > tonumber(indexedScores[2].score) then
					data.winner = 1
				else
					data.winner = 2
				end
				indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
			end
		end
		--If a manual winner is set use it
		if winner and data.resulttype ~= DEFAULT_RESULT_TYPE then
			if winner == 0 then
				data.resulttype = DRAW_RESULT_TYPE
			else
				data.resulttype = nil
			end
			data.winner = winner
			indexedScores = MatchGroupInput.setPlacement(indexedScores, winner, 1, 2)
		end
	end
	return data, indexedScores
end


-- Check if any team has a none-standard status
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckSpecialStatus(tbl)
	return Table.any(tbl,
		function (_, scoreinfo)
			return scoreinfo.status ~= STATUS_SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
end

---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckScoresSet(tbl)
	return Table.all(tbl, function (_, scoreinfo) return scoreinfo.status == STATUS_SCORE end)
end

--
-- match related functions
--

---@param match table
---@return table
function matchFunctions.getBestOf(match)
	local mapCount = 0
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		mapCount = mapIndex
	end
	match.bestof = mapCount
	return match
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored in lpdb, nor displayed
-- The discardMap function will check if a map should be removed
-- Remove all maps that should be removed.
---@param match table
---@return table
function matchFunctions.removeUnsetMaps(match)
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map') do
		if map.map == DUMMY_MAP_NAME then
			match[mapKey] = nil
		end
	end
	return match
end

-- Calculate the match scores based on the map results.
-- If it's a Best of 1, we'll take the exact score of that map
-- If it's not a Best of 1, we should count the map wins
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
---@param match table
---@return table
function matchFunctions.getScoreFromMapWinners(match)
	-- For best of 1, display the results of the single map
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	local newScores = {}
	local foundScores = false
	if match.bestof == 1 then
		if match.map1 then
			newScores = match.map1.scores
			foundScores = true
		end
	else -- For best of >1, disply the map wins
		for _, map in Table.iter.pairsByPrefix(match, 'map') do
			local winner = tonumber(map.winner)
			foundScores = true
			-- Only two opponents in C-OPS
			if winner and winner > 0 and winner <= 2 then
				newScores[winner] = (newScores[winner] or 0) + 1
			end
		end
	end
	if not opponent1.score and foundScores then
		opponent1.score = newScores[1] or 0
	end
	if not opponent2.score and foundScores then
		opponent2.score = newScores[2] or 0
	end
	match.opponent1 = opponent1
	match.opponent2 = opponent2
	return match
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

---@param match table
---@return string?
function matchFunctions.getMatchStatus(match)
	if match.resulttype == NOT_PLAYED_RESULT_TYPE then
		return match.status
	else
		return nil
	end
end

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = MatchGroupInput.getMapVeto(match),
		status = matchFunctions.getMatchStatus(match),
	}
	return match
end

---@param match table
---@return table
function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = STATUS_SCORE
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = NOT_PLAYED_SCORE
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				match = matchFunctions.getPlayers(match, opponentIndex, opponent.name)
			end
		end
	end

	-- Handle tournament status for unfinished matches
	if (not Logic.readBool(match.finished)) and Logic.isNotEmpty(match.status) then
		match.finished = match.status
	end

	if Table.includes(NOT_PLAYED_MATCH_STATUSES, match.finished) then
		match.resulttype = NOT_PLAYED_MATCH_STATUSES
		match.status = match.finished
		match.finished = false
		match.dateexact = false
	else
		-- see if match should actually be finished if score is set
		if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
			local threshold = match.dateexact and 30800 or 86400
			if match.timestamp + threshold < NOW then
				match.finished = true
			end
		end

		if Logic.readBool(match.finished) then
			match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
		end
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

-- Get Playerdata from Vars (get's set in TeamCards)
---@param match table
---@param opponentIndex integer
---@param teamName string
---@return table
function matchFunctions.getPlayers(match, opponentIndex, teamName)
	-- match._storePlayers will break after the first empty player. let's make sure we don't leave any gaps.
	local count = 1
	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		local player = match['opponent' .. opponentIndex .. '_p' .. playerIndex] or {}
		player = Json.parseIfString(player)
		local playerPrefix = teamName .. '_p' .. playerIndex
		player.name = player.name or Variables.varDefault(playerPrefix)
		player.flag = player.flag or Variables.varDefault(playerPrefix .. 'flag')
		player.displayname = player.displayname or Variables.varDefault(playerPrefix .. 'dn')
		if not Table.isEmpty(player) then
			match['opponent' .. opponentIndex .. '_p' .. count] = player
			count = count + 1
		end
	end
	return match
end

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
---@param map table
---@return boolean
function mapFunctions.discardMap(map)
	return map.map == DUMMY_MAP_NAME
end

-- Parse extradata information
---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
	}
	return map
end

---@param map table
---@return table
function mapFunctions._getHalfScores(map)
	map.extradata.t1sides = {}
	map.extradata.t2sides = {}
	map.extradata.t1halfs = {}
	map.extradata.t2halfs = {}

	local key = ''
	local overtimes = 0

	local function getOppositeSide(side)
		return side == SIDE_DEF and SIDE_ATK or SIDE_DEF
	end

	while true do
		local t1Side = map[key .. 't1firstside']
		if Logic.isEmpty(t1Side) or (t1Side ~= SIDE_DEF and t1Side ~= SIDE_ATK) then
			break
		end
		local t2Side = getOppositeSide(t1Side)

		-- Iterate over two Halfs (In regular time a half is 15 rounds, after that sides switch)
		for _ = 1, 2, 1 do
			if(map[key .. 't1' .. t1Side] and map[key .. 't2' .. t2Side]) then
				table.insert(map.extradata.t1sides, t1Side)
				table.insert(map.extradata.t2sides, t2Side)
				table.insert(map.extradata.t1halfs, tonumber(map[key .. 't1' .. t1Side]) or 0)
				table.insert(map.extradata.t2halfs, tonumber(map[key .. 't2' .. t2Side]) or 0)
				map[key .. 't1' .. t1Side] = nil
				map[key .. 't2' .. t2Side] = nil
				-- second half (sides switch)
				t1Side, t2Side = t2Side, t1Side
			end
		end

		overtimes = overtimes + 1
		key = 'o' .. overtimes
	end

	return map
end

-- Calculate Score and Winner of the map
-- Use the half information if available
---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}

	map = mapFunctions._getHalfScores(map)

	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score
		if Table.includes(ALLOWED_STATUSES, map['score' .. scoreIndex]) then
			score = map['score' .. scoreIndex]
		elseif Logic.isNotEmpty(map.extradata['t' .. scoreIndex .. 'halfs']) then
			score = MathUtil.sum(map.extradata['t' .. scoreIndex .. 'halfs'])
		else
			score = tonumber(map['score' .. scoreIndex])
		end
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
				obj.status = STATUS_SCORE
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = NOT_PLAYED_SCORE
			end
			map.scores[scoreIndex] = score
			indexedScores[scoreIndex] = obj
		end
	end

	if Table.includes(NOT_PLAYED_MATCH_STATUSES, map.finished) then
		map.resulttype = NOT_PLAYED_RESULT_TYPE
	else
		map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)
	end

	return map
end

return CustomMatchGroupInput
