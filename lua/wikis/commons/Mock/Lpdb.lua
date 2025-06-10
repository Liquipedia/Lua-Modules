---
-- @Liquipedia
-- page=Module:Mock/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

-- Parses a single condition into it's three components,
-- Eg. `[[field::!value]]` is parsed into `field`, `!`, `value`
local CONDITION_REGEX = '%[%[(%a+)::([!><]?)(.-)]]'

local mockLpdb = {}

local DEFAULTS = {
	limit = 20,
	offset = 0,
}

local _lpdb = {
	lpdb = mw.ext.LiquipediaDB.lpdb,
	lpdb_placement = mw.ext.LiquipediaDB.lpdb_placement,
	lpdb_standingsentry = mw.ext.LiquipediaDB.lpdb_standingsentry,
	lpdb_standingstable = mw.ext.LiquipediaDB.lpdb_standingstable,
	lpdb_squadplayer = mw.ext.LiquipediaDB.lpdb_squadplayer,
}

---@param callbackFunction? fun(dbTable: string, objectName: string, storedData: table)
function mockLpdb.setUp(callbackFunction)
	mockLpdb.callback = callbackFunction
	mw.ext.LiquipediaDB.lpdb = mockLpdb.lpdb
	mw.ext.LiquipediaDB.lpdb_placement = mockLpdb.lpdb_placement
	mw.ext.LiquipediaDB.lpdb_standingsentry = mockLpdb.lpdb_standingsentry
	mw.ext.LiquipediaDB.lpdb_standingstable = mockLpdb.lpdb_standingstable
	mw.ext.LiquipediaDB.lpdb_squadplayer = mockLpdb.lpdb_squadplayer
end

function mockLpdb.tearDown()
	mockLpdb.callback = nil
	mw.ext.LiquipediaDB.lpdb = _lpdb.lpdb
	mw.ext.LiquipediaDB.lpdb_placement = _lpdb.lpdb_placement
	mw.ext.LiquipediaDB.lpdb_standingsentry = _lpdb.lpdb_standingsentry
	mw.ext.LiquipediaDB.lpdb_standingstable = _lpdb.lpdb_standingstable
	mw.ext.LiquipediaDB.lpdb_squadplayer = _lpdb.lpdb_squadplayer
end

local dbStructure = {}
dbStructure.placement = {
	tournament = 'string',
	series = 'string?',
	parent = 'pagename',
	startdate = 'string?', -- TODO: Date type?
	date = 'string?', -- TODO: Date type?
	placement = 'number|string|nil',
	prizemoney = 'number?',
	individualprizemoney = 'number?',
	prizepoolindex = 'number?',
	weight = 'number?',
	mode = 'string?',
	liquipediatier = 'number|string|nil', -- TODO should be changed to number in the future
	liquipediatiertype = 'string?',
	game = 'string?',
	opponenttype = 'string',
	opponentname = 'string',
	opponenttemplate = 'string?',
	opponentplayers = TypeUtil.optional(TypeUtil.array(Opponent.types.Player)),
	qualifier = 'string?',
	qualifierpage = 'pagename?',
	qualifierurl = 'string?',
	extradata = 'struct?',
}
dbStructure.standingstable = {
	parent = 'pagename',
	standingsindex = 'number',
	title = 'string',
	tournament = 'string',
	section = 'string',
	type = TypeUtil.literalUnion('league', 'swiss'),
	matches = TypeUtil.optional(TypeUtil.array('string')),
	config = TypeUtil.table('string', 'boolean'),
	extradata = 'struct?',
}
dbStructure.standingsentry = {
	parent = 'pagename',
	standingsindex = 'number',
	opponenttype = 'string',
	opponentname = 'string',
	opponenttemplate = 'string?',
	opponentplayers = TypeUtil.optional(TypeUtil.array(Opponent.types.Player)),
	placement = 'string',
	definitestatus = 'string?',
	currentstatus = 'string',
	placementchange = 'number',
	scoreboards = 'table', -- TODO
	roundindex = 'number',
	extradata = 'struct?',
}
dbStructure.squadplayer = {
	id = 'string',
	link = 'pagename',
	name = 'string?',
	nationality = 'string?',
	image = 'string?',
	position = 'string?',
	role = 'string?',
	type = TypeUtil.literalUnion('player', 'staff'),
	newteam = 'string?',
	teamtemplate = 'string?', -- TODO: TeamTemplate type?
	newteamtemplate = 'string?', -- TODO: TeamTemplate type?
	joindate = 'string?', -- TODO: Date type?
	joindateref = 'string?',
	leavedate = 'string?', -- TODO: Date type?
	leavedateref = 'string?',
	inactivedate = 'string?', -- TODO: Date type?
	inactivedateref = 'string?',
	extradata = 'struct?',
}

--- Not yet supported in Mock is:
---- conditions with `OR` or `_`
---- query with `::`
---- order
---- groupby
---@generic T:LpdbBaseData
---@param dbTable `T`
---@param parameters table
---@return T[]
function mockLpdb.lpdb(dbTable, parameters)
	local lpdbData = mockLpdb._getMockData(dbTable)

	lpdbData = mockLpdb._applyConditions(lpdbData, parameters.conditions)

	lpdbData = mockLpdb._applyLimitOffset(lpdbData, parameters.limit, parameters.offset)

	lpdbData = mockLpdb._applyQuery(lpdbData, parameters.query)

	return lpdbData
end

---Fetches mock lpdb data from store
---@param dbTable string
---@return table
function mockLpdb._getMockData(dbTable)
	local data = Lua.import('Module:TestAssets/Lpdb/' .. dbTable)

	if not data then
		error(mw.message.new('liquipediadb-error-invalid-datatype'))
	end

	return data
end

---Filters the mock data based on an lpdb conditions string.
---@param data table
---@param conditions string?
---@return table
function mockLpdb._applyConditions(data, conditions)
	if String.isNotEmpty(conditions) then
		---@cast conditions -nil ---Since the engine cannot determine that isNotEmpty checks for nil, we remove the nil
		local condition = mockLpdb._parseConditions(conditions)
		return Array.filter(data, condition)
	end

	return data
end

---Applies limit and offset to mock data
---@param data table
---@param inputLimit number?
---@param inputOffset number?
---@return table
function mockLpdb._applyLimitOffset(data, inputLimit, inputOffset)
	local limit = tonumber(inputLimit) or DEFAULTS.limit
	local offset = tonumber(inputOffset) or DEFAULTS.offset

	return Array.sub(data, offset + 1, (offset + limit))
end

---Applies the field selectors (query) to the mock data
---@param data table
---@param query string?
---@return table
function mockLpdb._applyQuery(data, query)
	if String.isNotEmpty(query) then
		---@cast query -nil
		local fields = Array.map(mw.text.split(query, ','), String.trim)

		return Array.map(data, function(entry)
			return Table.map(entry, function(field, value)
				-- Use map as a filter since there's no applicable filter function in either Array or Table yet
				return field, Table.includes(fields, field) and value or nil
			end)
		end)
	end

	return data
end

---Parse a condition string into a function
---@param conditions string
---@return function
function mockLpdb._parseConditions(conditions)
	---@type {comparator:string, name:string, value:string}[]
	local criterias = {}

	for name, comparator, value in string.gmatch(conditions, CONDITION_REGEX) do
		table.insert(criterias, {name = name, comparator = comparator, value = value})
	end

	return function (entry)
		return Array.all(criterias, function (criteria)
			if criteria.comparator == '' then
				return entry[criteria.name] == criteria.value
			elseif criteria.comparator == '!' then
				return entry[criteria.name] ~= criteria.value
			elseif criteria.comparator == '>' then
				return entry[criteria.name] > criteria.value
			elseif criteria.comparator == '<' then
				return entry[criteria.name] < criteria.value
			else
				error('Unknown comparator: '.. tostring(criteria.comparator))
			end
		end)
	end
end

function mockLpdb._deserializeJson(value)
	return Json.parseIfTable(value) or value
end

function mockLpdb._verifyInsertion(dbTable, objectname, data)
	local parsedData = Table.mapValues(data, mockLpdb._deserializeJson)

	TypeUtil.assertValue(objectname, 'string')
	TypeUtil.assertValue(parsedData, TypeUtil.struct(dbStructure[dbTable]), { maxDepth = 3, name = dbTable})

	if mockLpdb.callback then
		mockLpdb.callback(dbTable, objectname, parsedData)
	end
end

---Stores data into LPDB Placement
---@param objectname string
---@param data table
function mockLpdb.lpdb_placement(objectname, data)
	mockLpdb._verifyInsertion('placement', objectname, data)
end

---Stores data into LPDB StandingsTable
---@param objectname string
---@param data table
function mockLpdb.lpdb_standingstable(objectname, data)
	mockLpdb._verifyInsertion('standingstable', objectname, data)
end

---Stores data into LPDB StandingsEntry
---@param objectname string
---@param data table
function mockLpdb.lpdb_standingsentry(objectname, data)
	mockLpdb._verifyInsertion('standingsentry', objectname, data)
end

---Stores data into LPDB SquadPlayer
---@param objectname string
---@param data table
function mockLpdb.lpdb_squadplayer(objectname, data)
	mockLpdb._verifyInsertion('squadplayer', objectname, data)
end

return mockLpdb
