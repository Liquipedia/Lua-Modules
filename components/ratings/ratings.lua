---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Ratings = {}

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lpdb = require('Module:Lpdb')
local Table = require('Module:Table')
local String = require('Module:StringUtils')

-- Parameters related to LPDB
local STATIC_CONDITIONS_MATCH = '[[mode::3v3]] AND [[finished::1]] AND [[liquipediatiertype::!School]]'
local STATIC_CONDITIONS_LPR_TRANSFER = '[[namespace::4]] AND [[type::LPR_TRANSFER]]'
local STATIC_CONDITIONS_LPR_RATING = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

-- Parameters related to rating table
local DAYS_IDLE_BEFORE_CLEANUP = 100
local MATCHES_TO_KEEP_PER_TEAM = 5

-- Parameters for the rating calculation
local RATING_RANGE_FACTOR = 700.0
local RATING_K = 15
local RATING_INIT_VALUE = 1250

---@param date osdate
---@param customDays integer?
---@return osdate
local function stepDate(date, customDays)
	local newDate = Table.copy(date)
	newDate.day = newDate.day + (customDays or 1)
	return newDate
end

---@param str string
---@return osdate
---@overload fun():nil
local function parseDate(str)
	if not str then
		return
	end
	local y, m, d = str:match('^(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)')
	-- default to month and day = 1 if not set
	if String.isEmpty(m) then
		m = 1
	end
	if String.isEmpty(d) then
		d = 1
	end
	-- create time
	return {year = y, month = m, day = d}
end

local function getDateRangeConditions(dateStart, dateEnd)
	dateEnd = dateEnd or dateStart
	return '[[date::>' .. os.date('!%x', os.time(stepDate(dateStart, -1))) .. ' 23:59:59' .. ']]' ..
		' AND [[date::<' .. os.date('!%x', os.time(stepDate(dateEnd))) .. ']]'
end

local function getAllTransfers()
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

local function calcRating(rpSelf, rpOther, score1, score2, match)
	local modExternalTable = {1, 1}
	local tier = tonumber(match.liquipediatier)
	local tierType = match.liquipediatiertype

	local ratingSelf = rpSelf.rating
	local ratingOther = rpOther.rating

	-- some static parameters
	local expectation = 1 / (1 + 10 ^ ((ratingOther - ratingSelf) / RATING_RANGE_FACTOR))

	local max = math.max(score1, score2)
	local win = (score1 > score2)

	-- static tier modifier
	local mod = 1
	-- dynamic tier modifier
	local mod2 = 1
	-- low match count rating bonus per tier
	local mod3 = 1
	-- BestOf modifier
	local modBO = 1
	if max < 2 then
		modBO = 0.6
	elseif max > 3 then
		modBO = 1.15
	end
	-- external modifier
	local modExternal = modExternalTable[win and 1 or 2]

	-- increase possible won points if number of matches is low
	if win and rpSelf.matches < 30 then
		modExternal = modExternal * 1.5
	end

	-- tierType
	local modTierType = 1
	if tierType == 'Qualifier' then
		modTierType = 0.67
	end

	-- tier modification
	local mWin = 600
	local mLose = 600

	local function calcMod2(base, multiplier)
		return win and (0.5 / (1 + 10 ^ ((ratingSelf - base) / mWin))) + 1 or
				((-1 / (1 + 10 ^ ((ratingSelf - base) / mLose))) + 1) * multiplier
	end

	if tier == 1 then
		mod = 4.5
		mod2 = calcMod2(2300, 1)
	elseif tier == 2 then
		mod = 3
		mod2 = calcMod2(2100, 1.22)
	elseif tier == 3 then
		mod = 2
		mod2 = calcMod2(2100, 1.1)
	elseif tier == 4 then
		mod = 0.75
		mod2 = calcMod2(1800, 1)
	else
		mod = 0.2
		mod2 = calcMod2(1800, 1)
	end

	local delta = RATING_K * ((win and 1 or 0) - expectation) * mod * mod2 * mod3 * modBO * modExternal * modTierType

	-- set minimal gain/loss to +/- 1
	if win and delta < 1 then
		delta = 1
	elseif not win and delta > -1 then
		delta = -1
	end

	rpSelf.matches = rpSelf.matches + 1

	-- set streak
	if (rpSelf.streak > 0) then
		rpSelf.streak = win and (rpSelf.streak + 1) or -1
	elseif (rpSelf.streak < 0) then
		rpSelf.streak = win and 1 or (rpSelf.streak - 1)
	else
		rpSelf.streak = win and 1 or -1
	end

	--set last matches
	if Table.size(rpSelf.lastmatches) >= MATCHES_TO_KEEP_PER_TEAM then
		table.remove(rpSelf.lastmatches, 1)
	end
	table.insert(rpSelf.lastmatches, {
		id = match.match2id,
		ratingChange = delta,
		timestamp = os.time(parseDate(match.date)),
	})

	--[[
	if roster ~= nil then
		if roster.p1 ~= nil and roster.p1 ~= "" then
			self.last_roster = roster
		end
	end
	--]]

	return ratingSelf + delta
end

local function storeRatingTable(ratingTable, date, name)
	mw.log('stored ' .. date)
	local placementsToStore = {}
	local ratingTableToStore = {}
	for team, data in Table.iter.spairs(ratingTable, function(tbl, a, b) return tbl[a].rating > tbl[b].rating end) do
		if data.matches > 10 then
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

local function storeTransfer(from, to, date, mod)
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

local function getLatestSnapshotDate(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'date',
			limit = 1,
			order = 'date DESC',
			conditions = STATIC_CONDITIONS_LPR_RATING .. ' AND [[name::' .. name .. ']] AND [[pagename::!' .. mw.title.getCurrentTitle().text .. ']]'
		}
	)
	return (res[1] or {}).date
end

local function getRatingTable(date, name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata',
			limit = 1,
			conditions = STATIC_CONDITIONS_LPR_RATING ..
			' AND [[name::' .. name .. ']] AND [[date::' .. os.date('!%x', os.time(date)) .. ']]'
		}
	)
	return Json.parseIfString(((res[1] or {}).extradata or {}).table) or {}
end

local processedMatches = 0
local allMatches = 0
local matchids = {}

local function processMatch(ratingTable, match)
	allMatches = allMatches + 1

	if matchids[match.match2id] then
		return
	end
	matchids[match.match2id] = true

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
	local newRating1 = calcRating(rp1, rp2, op1.score, op2.score, match)
	local newRating2 = calcRating(rp2, rp1, op2.score, op1.score, match)

	-- apply new ratings
	rp1.rating = newRating1
	rp2.rating = newRating2

	-- update rating table
	ratingTable[op1.name] = rp1
	ratingTable[op2.name] = rp2

	processedMatches = processedMatches + 1
end

local function processTransfer(ratingTable, transfer)
	local data = (transfer.extradata or {})
	local from = data.from
	local to = data.to
	local modifier = data.mod or 1

	if String.isEmpty(from) then
		-- New Team
		mw.log('New', from, to)
	elseif String.isEmpty(to) then
		-- removal
		ratingTable[from] = nil
		mw.log('Del', from, to)
	else
		-- transfer
		ratingTable[to], ratingTable[from] = ratingTable[from], nil
		ratingTable[to] = ratingTable[to]
		if ratingTable[to] then
			ratingTable[to].rating = (ratingTable[to].rating - RATING_INIT_VALUE) * modifier + RATING_INIT_VALUE
		end
		mw.log('Move', from, to)
	end
end

local function cleanRatingTable(ratingTable, today)
	local cutOff = os.time(stepDate(today, -DAYS_IDLE_BEFORE_CLEANUP))
	return Table.filterByKey(ratingTable, function(_, team)
		return os.difftime(team.lastmatches[#team.lastmatches].timestamp, cutOff) >= 0
	end)
end

local function newDay(ratingTable, transfersForDay)
	if not transfersForDay then
		return
	end
	local transferHandler = FnUtil.curry(processTransfer, ratingTable)
	Array.forEach(transfersForDay, transferHandler)
end

local function newMonth(ratingTable, date, id, dateFormat)
	ratingTable = cleanRatingTable(ratingTable, dateFormat)
	storeRatingTable(ratingTable, date, id)
end

local function initStepDate(ratingTable, transfers, id)
	local hasFirstMonth = false
	---@param from osdate
	---@param to osdate?
	---@return osdate
	return function(from, to)
		if not to then
			to = stepDate(from)
		end
		local current = from
		local prev = stepDate(from, -1)
		while os.time(current) < os.time(to) do
			local date = os.date('!%F', os.time(current)) --[[@as osdate]]

			if os.date('%m', os.time(prev)) ~= os.date('%m', os.time(current)) then
				if hasFirstMonth then
					newMonth(ratingTable, date, id, current)
				else
					hasFirstMonth = true
				end
			end

			newDay(ratingTable, transfers[date])

			prev = current
			current = stepDate(current)
		end
		return to
	end
end

--- calculates the rating and stores it to the LPDB
function Ratings.calc(frame)
	-- [[pagename::" .. mw.title.getCurrentTitle().text .. "]]"

	local args = Arguments.getArgs(frame)
	local id = args.id
	if String.isEmpty(id) then
		return '<code>id</code> is empty, needs to be set'
	end

	-- date params
	local dateFrom = parseDate(args.dateFrom or getLatestSnapshotDate(id))
	local dateTo = parseDate(args.dateTo or os.date('!%F')--[[@as string]])

	-- Fetch data
	local ratingTable = Table.map(getRatingTable(dateFrom, id), function(key, value)
		-- Ensure key is string, can be lost in the parsing
		return tostring(key), value
	end)
	local transfers = getAllTransfers()

	-- perform calculation
	local lastDate = stepDate(dateFrom, -1)

	local newDateFunc = initStepDate(ratingTable, transfers, id)

	Lpdb.executeMassQuery('match2', {
		query = 'date,match2opponents,liquipediatier,liquipediatiertype,match2id,extradata',
		order = 'date ASC',
		limit = 500,
		conditions = getDateRangeConditions(dateFrom, dateTo) .. ' AND ' .. STATIC_CONDITIONS_MATCH
	}, function (match)
		-- Check and handle new dates
		lastDate = newDateFunc(lastDate, parseDate(match.date))

		-- process match
		processMatch(ratingTable, match)
	end)

	-- Tick through any remaining days
	while os.time(lastDate) <= os.time(dateTo) do
		lastDate = newDateFunc(lastDate)
	end

	if dateTo.day ~= 1 then
		newMonth(ratingTable, os.date('!%F', os.time(dateTo)) --[[@as osdate]], id, dateTo)
	end

	-- text output
	local out = ''
	out = out .. 'All matches: ' .. allMatches .. '<br>'
	out = out .. 'Valid matches: ' .. processedMatches .. '<br>'
	--[[for team, data in Table.iter.spairs(ratingTable, function(tbl, a, b) return tbl[a].rating > tbl[b].rating end) do
		out = out .. team .. " " .. Json.stringify(data) .. "<br>"
	end ]]
	--
	return out
end

function Ratings.transfer(frame)
	local args = Arguments.getArgs(frame)
	local date = os.time(parseDate(args.date))
	local from = mw.ext.TeamTemplate.teampage(args.from, args.date)
	local to = String.isNotEmpty(args.to) and mw.ext.TeamTemplate.teampage(args.to, args.date) or ''
	if String.startsWith(from, '<div class=') then
		return from
	elseif String.startsWith(to, '<div class=') then
		return to
	else
		storeTransfer(from, to, date, tonumber(args.mod))
	end
	return '<code>' .. args.date .. ': ' .. from .. ' --> ' .. to .. '</code><br>'
end

function Ratings.store(frame)
	local args = Arguments.getArgs(frame)
	local date = os.time(parseDate(args.date))
	local id = args.id
	local rawTable = Json.parse(args.table)
	local ratingTable = {}
	for key, data in pairs(rawTable) do
		local team = mw.ext.TeamTemplate.teampage(key, args.date)
		if not String.startsWith(team, '<div class=') and tonumber(data.rating) then
			ratingTable[team] = {
				rating = tonumber(data.rating),
				streak = tonumber(data.streak),
				matches = tonumber(data.matches),
				lastmatches = data.lastmatches
			}
		end
	end
	storeRatingTable(ratingTable, date, id)
	return Json.stringify(rawTable)
end

return Ratings
