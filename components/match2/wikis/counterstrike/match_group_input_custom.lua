---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local MathUtil = require('Module:MathUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local EarningsOf = require('Module:Earnings of')

local Opponent = Lua.import('Module:Opponent')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input')

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L', 'D'}
local NP_MATCH_STATUS = {'cancelled','canceled', 'postponed'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_MAPS = 9
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local FEATURED_TIERS = {1, 2}
local MIN_EARNINGS_FOR_FEATURED = 200000

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
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getLinks(match)
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

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer = true})
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

--
--
-- function to check for draws
---@param tbl table[]
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
			data.resulttype = 'draw'
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
		elseif MatchGroupInput.hasSpecialStatus(indexedScores) then
			data.winner = MatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = 'default'
			if MatchGroupInput.hasForfeit(indexedScores) then
				data.walkover = 'ff'
			elseif MatchGroupInput.hasDisqualified(indexedScores) then
				data.walkover = 'dq'
			elseif MatchGroupInput.hasDefaultWinLoss(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		elseif CustomMatchGroupInput.placementCheckScoresSet(indexedScores) then
			--CS only has exactly 2 opponents, neither more or less
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
		if winner and data.resulttype ~= 'default' then
			if winner == 0 then
				data.resulttype = 'draw'
			else
				data.resulttype = nil
			end
			data.winner = winner
			indexedScores = MatchGroupInput.setPlacement(indexedScores, winner, 1, 2)
		end
	end
	return data, indexedScores
end

---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckScoresSet(tbl)
	return Table.all(tbl, function (_, scoreinfo) return scoreinfo.status == 'S' end)
end

--
-- match related functions
--

---@param match table
---@return table
function matchFunctions.getBestOf(match)
	local mapCount = 0
	for i = 1, MAX_NUM_MAPS do
		if match['map' .. i] then
			mapCount = mapCount + 1
		else
			break
		end
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
	for i = 1, MAX_NUM_MAPS do
		if match['map' .. i] then
			if mapFunctions.discardMap(match['map' .. i]) then
				match['map' .. i] = nil
			end
		else
			break
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
		for i = 1, MAX_NUM_MAPS do
			if match['map' .. i] then
				local winner = tonumber(match['map' .. i].winner)
				foundScores = true
				-- Only two opponents in CS
				if winner and winner > 0 and winner <= 2 then
					newScores[winner] = (newScores[winner] or 0) + 1
				end
			else
				break
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
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_valve_tier'))
	match.status = Logic.emptyOr(match.status, Variables.varDefault('tournament_status'))

	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getLinks(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {}

	local links = match.links

	local platforms = mw.loadData('Module:MatchExternalLinks')
	table.insert(platforms, {name = 'vod2', isMapStats = true})

	for _, platform in ipairs(platforms) do
		-- Stat external links inserted in {{Map}}
		if Logic.isNotEmpty(platform) then
			local platformLinks = {}
			local name = platform.name
			local prefixLink = platform.prefixLink or ''
			local suffixLink = platform.suffixLink or ''

			if match[name] then
				table.insert(platformLinks, {prefixLink .. match[name] .. suffixLink, 0})
				match[name] = nil
			end

			if platform.isMapStats then
				for i = 1, match.bestof do
					local map = match['map' .. i]
					if map and map[platform.name] then
						table.insert(platformLinks, {prefixLink .. match['map' .. i][name] .. suffixLink, i})
						match['map' .. i][platform.name] = nil
					end
				end
			else
				if platform.max then
					for i = 2, platform.max, 1 do
						if match[platform.name .. i] then
							table.insert(platformLinks, {prefixLink .. match[name .. i] .. suffixLink, i})
							match[platform.name .. i] = nil
						end
					end
				end
			end

			if #platformLinks > 0 then
				links[name] = platformLinks
			end
		end
	end

	return match
end

---@param match table
---@return string?
function matchFunctions.getMatchStatus(match)
	if match.resulttype == 'np' then
		return match.status
	else
		return nil
	end
end

---@param name string?
---@param year string|osdate
---@return number
function matchFunctions.getEarnings(name, year)
	if Logic.isEmpty(name) then
		return 0
	end

	return tonumber(EarningsOf._team(name, {sdate = (year-1) .. '-01-01', edate = year .. '-12-31'})) --[[@as number]]
end

---@param match table
---@return boolean
function matchFunctions.isFeatured(match)
	if Table.includes(FEATURED_TIERS, tonumber(match.liquipediatier)) then
		return true
	end
	if Logic.isNotEmpty(match.publishertier) then
		return true
	end

	if match.timestamp == DateExt.defaultTimestamp then
		return false
	end

	local opponent1, opponent2 = match.opponent1, match.opponent2
	local year = os.date('%Y')

	if
		opponent1.type == Opponent.team and
		matchFunctions.getEarnings(opponent1.name, year) >= MIN_EARNINGS_FOR_FEATURED
	or
		opponent2.type == Opponent.team and
		matchFunctions.getEarnings(opponent2.name, year) >= MIN_EARNINGS_FOR_FEATURED
	then
		return true
	end

	return false
end

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = MatchGroupInput.getMapVeto(match),
		status = matchFunctions.getMatchStatus(match),
		overturned = Logic.isNotEmpty(match.overturned),
		featured = matchFunctions.isFeatured(match),
		hidden = Logic.readBool(Variables.varDefault('match_hidden'))
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
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
					maxNumPlayers = 5, resolveRedirect = true, applyUnderScores = true
				})
			end
		end
	end

	-- Handle tournament status for unfinished matches
	if (not Logic.readBool(match.finished)) and Logic.isNotEmpty(match.status) then
		match.finished = match.status
	end

	if Table.includes(NP_MATCH_STATUS, match.finished) then
		match.resulttype = 'np'
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

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
---@param map table
---@return boolean
function mapFunctions.discardMap(map)
	if map.map == DUMMY_MAP_NAME then
		return true
	else
		return false
	end
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
	map.extradata['t1sides'] = {}
	map.extradata['t2sides'] = {}
	map.extradata['t1halfs'] = {}
	map.extradata['t2halfs'] = {}

	local key = ''
	local overtimes = 0

	local function getOpossiteSide(side)
		return side == 'ct' and 't' or 'ct'
	end

	while true do
		local t1Side = map[key .. 't1firstside']
		if Logic.isEmpty(t1Side) or (t1Side ~= 'ct' and t1Side ~= 't') then
			break
		end
		local t2Side = getOpossiteSide(t1Side)

		-- Iterate over two Halfs (In regular time a half is 15 rounds, after that sides switch)
		for _ = 1, 2, 1 do
			if(map[key .. 't1' .. t1Side] and map[key .. 't2' .. t2Side]) then
				table.insert(map.extradata['t1sides'], t1Side)
				table.insert(map.extradata['t2sides'], t2Side)
				table.insert(map.extradata['t1halfs'], tonumber(map[key .. 't1' .. t1Side]) or 0)
				table.insert(map.extradata['t2halfs'], tonumber(map[key .. 't2' .. t2Side]) or 0)
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
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
			end
			map.scores[scoreIndex] = score
			indexedScores[scoreIndex] = obj
		end
	end

	if map.finished == 'skip' then
		map.resulttype = 'np'
	else
		map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)
	end

	return map
end

return CustomMatchGroupInput
