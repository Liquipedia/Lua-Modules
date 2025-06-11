---
-- @Liquipedia
-- page=Module:Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lpdb = require('Module:Lpdb')
local Table = require('Module:Table')
local String = require('Module:StringUtils')

--- Liquipedia Ratings (LPR)
local Ratings = {}

-- Parameters related to LPDB
local STATIC_CONDITIONS_MATCH = '[[mode::3v3]] AND [[finished::1]] AND [[liquipediatiertype::!School]]'
local STATIC_CONDITIONS_LPR_TRANSFER = '[[namespace::4]] AND [[type::LPR_TRANSFER]]'
local STATIC_CONDITIONS_LPR_SNAPSHOT = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

-- Parameters related to rating table
local DAYS_IDLE_BEFORE_CLEANUP = 100
local MATCHES_TO_KEEP_PER_TEAM = 5
local MIN_MATCHES_TO_STORE = 10

-- Parameters for the rating calculation
local RATING_RANGE_FACTOR = 700.0
local RATING_K = 15
local RATING_INIT_VALUE = 1250

-- Tracking variables
local _processedMatches = 0
local _allMatches = 0
local _seenMatchIds = {}

---@param date osdateparam
---@param customDays integer?
---@return osdateparam
function Ratings._stepDate(date, customDays)
	local newDate = Table.copy(date)
	newDate.day = newDate.day + (customDays or 1)
	return newDate
end

function Ratings._getDateRangeConditions(dateStart, dateEnd)
	dateEnd = dateEnd or dateStart
	return '[[date::>' .. os.date('!%x', os.time(Ratings._stepDate(dateStart, -1))) .. ' 23:59:59' .. ']]' ..
		' AND [[date::<' .. os.date('!%x', os.time(Ratings._stepDate(dateEnd))) .. ']]'
end

function Ratings._getAllTransfers()
	local transfersAtDate = {}
	Lpdb.executeMassQuery('datapoint', {
		query = 'date, extradata',
		order = 'date ASC',
		conditions = STATIC_CONDITIONS_LPR_TRANSFER -- TODO: Date Range for memory performance
	}, function (transfer)
		local date = string.sub(transfer.date, 0, 10)
		if not transfersAtDate[date] then
			transfersAtDate[date] = {}
		end
		table.insert(transfersAtDate[date], transfer)
	end)

	return transfersAtDate
end

function Ratings._calcRatingChange(rpSelf, rpOther, score1, score2, match)
	local modExternalTable = {1, 1}
	local tier = tonumber(match.liquipediatier)
	local tierType = match.liquipediatiertype

	local ratingSelf = rpSelf.rating
	local ratingOther = rpOther.rating

	-- Expected score (https://en.wikipedia.org/wiki/Elo_rating_system#Mathematical_details)
	local expectation = 1 / (1 + 10 ^ ((ratingOther - ratingSelf) / RATING_RANGE_FACTOR))

	local winnerScore = math.max(score1, score2)
	local won = (score1 > score2)

	-- Modifiers
	local modifierTier, modifierDynamic, modifierLowMatchCount, modifierTierType, modifierBestOf

	-- Best of
	if winnerScore < 2 then
		modifierBestOf = 0.6
	elseif winnerScore > 3 then
		modifierBestOf = 1.15
	else
		modifierBestOf = 1
	end

	-- External modifier
	local modifierExternal = modExternalTable[won and 1 or 2]

	-- Increase points if number of matches is low when winning
	if won and rpSelf.matches < 30 then
		modifierLowMatchCount = 1.5
	else
		modifierLowMatchCount = 1
	end

	-- TierType Modifier
	if tierType == 'Qualifier' then
		modifierTierType = 0.67
	else
		modifierTierType = 1
	end

	-- Modifications based on tier
	local mWin = 600
	local mLose = 600

	local function calculateDynamicModifier(base, multiplier)
		return won and (0.5 / (1 + 10 ^ ((ratingSelf - base) / mWin))) + 1 or
				((-1 / (1 + 10 ^ ((ratingSelf - base) / mLose))) + 1) * multiplier
	end

	if tier == 1 then
		modifierTier = 4.5
		modifierDynamic = calculateDynamicModifier(2300, 1)
	elseif tier == 2 then
		modifierTier = 3
		modifierDynamic = calculateDynamicModifier(2100, 1.22)
	elseif tier == 3 then
		modifierTier = 2
		modifierDynamic = calculateDynamicModifier(2100, 1.1)
	elseif tier == 4 then
		modifierTier = 0.75
		modifierDynamic = calculateDynamicModifier(1800, 1)
	else
		modifierTier = 0.2
		modifierDynamic = calculateDynamicModifier(1800, 1)
	end

	local delta = RATING_K * ((won and 1 or 0) - expectation) * modifierTier * modifierDynamic * modifierLowMatchCount
			* modifierBestOf * modifierExternal * modifierTierType

	-- Force minimal gain/loss to +/- 1
	if won and delta < 1 then
		delta = 1
	elseif not won and delta > -1 then
		delta = -1
	end

	-- Update streak
	if (rpSelf.streak > 0) then
		rpSelf.streak = won and (rpSelf.streak + 1) or -1
	elseif (rpSelf.streak < 0) then
		rpSelf.streak = won and 1 or (rpSelf.streak - 1)
	else
		rpSelf.streak = won and 1 or -1
	end

	-- Add to team's last matches
	if Table.size(rpSelf.lastmatches) >= MATCHES_TO_KEEP_PER_TEAM then
		table.remove(rpSelf.lastmatches, 1)
	end
	table.insert(rpSelf.lastmatches, {
		id = match.match2id,
		ratingChange = delta,
		timestamp = os.time(Date.parseIsoDate(match.date)),
	})

	-- Update matches played
	rpSelf.matches = rpSelf.matches + 1

	return ratingSelf + delta
end

function Ratings._storeRatingTable(ratingTable, date, name)
	local placementsToStore = {}
	local ratingTableToStore = {}
	for team, data in Table.iter.spairs(ratingTable, function(tbl, a, b) return tbl[a].rating > tbl[b].rating end) do
		if data.matches >= MIN_MATCHES_TO_STORE then
			table.insert(placementsToStore, team)
			ratingTableToStore[team] = data
		end
	end

	mw.ext.LiquipediaDB.lpdb_datapoint(
		'LPR_SNAPSHOT_' .. date .. '_' .. name,
		{
			date = date,
			type = 'LPR_SNAPSHOT',
			name = name,
			extradata = Json.stringify({
				ranks = placementsToStore,
				table = ratingTableToStore
			})
		}
	)
end

function Ratings._storeTransfer(from, to, date, mod)
	date = os.date('!%x', date)
	mw.ext.LiquipediaDB.lpdb_datapoint(
		'LPR_TRANSFER_' .. date .. '_' .. from .. '_' .. to,
		{
			date = date,
			type = 'LPR_TRANSFER',
			extradata = Json.stringify({
				from = from,
				to = to,
				mod = mod,
			})
		}
	)
end

function Ratings._getLatestSnapshotDate(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'date',
			limit = 1,
			order = 'date DESC',
			conditions = STATIC_CONDITIONS_LPR_SNAPSHOT ..
					' AND [[name::' .. name .. ']] AND [[pagename::!' .. mw.title.getCurrentTitle().text .. ']]'
		}
	)
	return (res[1] or {}).date
end

function Ratings._getRatingTable(date, name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata',
			limit = 1,
			conditions = STATIC_CONDITIONS_LPR_SNAPSHOT ..
					' AND [[name::' .. name .. ']] AND [[date::' .. os.date('!%x', os.time(date)) .. ']]'
		}
	)
	return Json.parseIfString(((res[1] or {}).extradata or {}).table) or {}
end

function Ratings._processMatch(ratingTable, match)
	_allMatches = _allMatches + 1

	if _seenMatchIds[match.match2id] then
		return
	end
	_seenMatchIds[match.match2id] = true

	-- get opponents
	local op1 = (match.match2opponents or {})[1]
	local op2 = (match.match2opponents or {})[2]
	local extradata = match.extradata or {}

	-- check match for validity
	if not tonumber(match.liquipediatier) or not op1 or not op2 or op1.status ~= 'S' or op1.status ~= 'S' or
			String.isEmpty(op1.name) or String.isEmpty(op2.name) or (op1.score == 0 and op2.score == 0)
			or extradata.liquipediatiertype2 == 'School' then
		return
	end

	-- get rating participants
	local rp1 = ratingTable[op1.name] or {rating = RATING_INIT_VALUE, matches = 0, streak = 0, lastmatches = {}}
	local rp2 = ratingTable[op2.name] or {rating = RATING_INIT_VALUE, matches = 0, streak = 0, lastmatches = {}}

	-- calculate the new ratings
	local newRating1 = Ratings._calcRatingChange(rp1, rp2, op1.score, op2.score, match)
	local newRating2 = Ratings._calcRatingChange(rp2, rp1, op2.score, op1.score, match)

	-- apply new ratings
	rp1.rating = newRating1
	rp2.rating = newRating2

	-- update rating table
	ratingTable[op1.name] = rp1
	ratingTable[op2.name] = rp2

	_processedMatches = _processedMatches + 1
end

function Ratings._processTransfer(ratingTable, transfer)
	local data = (transfer.extradata or {})
	local from = data.from
	local to = data.to
	local modifier = tonumber(data.mod) or 1

	if String.isEmpty(to) then
		-- Removal
		ratingTable[from] = nil
	elseif String.isNotEmpty(from) then
		-- Transfer
		ratingTable[to], ratingTable[from] = ratingTable[from], nil
		ratingTable[to] = ratingTable[to]
		if ratingTable[to] then
			ratingTable[to].rating = (ratingTable[to].rating - RATING_INIT_VALUE) * modifier + RATING_INIT_VALUE
		end
	end
end

function Ratings._cleanRatingTable(ratingTable, today)
	local cutOff = os.time(Ratings._stepDate(today, -DAYS_IDLE_BEFORE_CLEANUP))
	return Table.filterByKey(ratingTable, function(_, team)
		return os.difftime(team.lastmatches[#team.lastmatches].timestamp, cutOff) >= 0
	end)
end

function Ratings._newDay(ratingTable, transfersForDay)
	if not transfersForDay then
		return
	end
	local transferHandler = FnUtil.curry(Ratings._processTransfer, ratingTable)
	Array.forEach(transfersForDay, transferHandler)
end

function Ratings._newMonth(ratingTable, date, id, dateFormat)
	ratingTable = Ratings._cleanRatingTable(ratingTable, dateFormat)
	Ratings._storeRatingTable(ratingTable, date, id)
end

function Ratings._initStepDate(ratingTable, transfers, id)
	local hasFirstMonth = false
	---@param from osdateparam
	---@param to osdateparam?
	---@return osdateparam
	return function(from, to)
		if not to then
			to = Ratings._stepDate(from)
		end
		local current = from
		local prev = Ratings._stepDate(from, -1)
		while os.time(current) < os.time(to) do
			local date = os.date('!%F', os.time(current))

			if os.date('%m', os.time(prev)) ~= os.date('%m', os.time(current)) then
				if hasFirstMonth then
					Ratings._newMonth(ratingTable, date, id, current)
				else
					hasFirstMonth = true
				end
			end

			Ratings._newDay(ratingTable, transfers[date])

			prev = current
			current = Ratings._stepDate(current)
		end
		return to
	end
end

--- calculates the rating and stores it to the LPDB
function Ratings.calc(frame)
	local args = Arguments.getArgs(frame)

	local id = args.id
	if String.isEmpty(id) then
		return '<code>id</code> is empty, needs to be set'
	end

	-- date params
	local dateFrom = Date.parseIsoDate(args.dateFrom or Ratings._getLatestSnapshotDate(id))
	local dateTo = Date.parseIsoDate(args.dateTo or os.date('!%F') --[[@as string]])

	-- Fetch data
	local ratingTable = Table.map(Ratings._getRatingTable(dateFrom, id), function(key, value)
		-- Ensure key is string, can be lost in the json parsing
		return tostring(key), value
	end)
	local transfers = Ratings._getAllTransfers()

	-- perform calculation
	local lastDate = Ratings._stepDate(dateFrom, -1)

	local newDateFunc = Ratings._initStepDate(ratingTable, transfers, id)

	Lpdb.executeMassQuery('match2', {
		query = 'date,match2opponents,liquipediatier,liquipediatiertype,match2id,extradata',
		order = 'date ASC',
		limit = 500,
		conditions = Ratings._getDateRangeConditions(dateFrom, dateTo) .. ' AND ' .. STATIC_CONDITIONS_MATCH
	}, function (match)
		-- Check and handle new dates
		lastDate = newDateFunc(lastDate, Date.parseIsoDate(match.date))

		-- Process match
		Ratings._processMatch(ratingTable, match)
	end)

	-- Tick through any remaining days
	while os.time(lastDate) <= os.time(dateTo) do
		lastDate = newDateFunc(lastDate)
	end

	if dateTo.day ~= 1 then
		Ratings._newMonth(ratingTable, os.date('!%F', os.time(dateTo)), id, dateTo)
	end

	-- Display something
	local output = {}
	table.insert(output, 'All matches: ' .. _allMatches)
	table.insert(output, 'Valid matches: ' .. _processedMatches)

	return table.concat(output, '<br>')
end

function Ratings.transfer(frame)
	local args = Arguments.getArgs(frame)
	local date = os.time(Date.parseIsoDate(args.date))
	local from = mw.ext.TeamTemplate.teampage(args.from, args.date)
	local to = String.isNotEmpty(args.to) and mw.ext.TeamTemplate.teampage(args.to, args.date) or ''
	if String.startsWith(from, '<div class=') then
		return from
	elseif String.startsWith(to, '<div class=') then
		return to
	else
		Ratings._storeTransfer(from, to, date, tonumber(args.mod))
	end
	return '<code>' .. args.date .. ': ' .. from .. ' --> ' .. to .. '</code><br>'
end

return Ratings
