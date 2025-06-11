---
-- @Liquipedia
-- page=Module:Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')
local TextSanitizer = require('Module:TextSanitizer')

local Lpdb = {}

local MAXIMUM_QUERY_LIMIT = 5000

-- Executes a mass query.
--[==[
Loops LPDB queries to e.g.
- circumvent the maximum limit of 5000
- use additional filtering (e.g. because LPDB does not support it)
	and query so long until a certain amount of elements is found
	or additional limitations are reached

example:
```
	local foundMatchIds = {}
	local getMatchId = function(match)
		if #foundMatchIds < args.matchLimit then
			if HeadToHead._fitsAdditionalConditions(args, match) then
				table.insert(foundMatchIds, match.match2id)
			end
		else
			return false
		end
	end

	local queryParameters = {
		conditions = conditions,
		order = 'date ' .. args.order,
		limit = _LPDB_QUERY_LIMIT,
		query = 'pagename, winner, finished, date, dateexact, links, '
			.. 'bestof, vod, tournament, tickername, shortname, icon, icondark, '
			.. 'extradata, match2opponents, match2games, mode, match2id, match2bracketid',
	}
	Lpdb.executeMassQuery('match2', queryParameters, getMatchId)

	return foundMatchIds
```
]==]
---@generic T
---@param tableName `T`
---@param queryParameters table
---@param itemChecker fun(item: T): boolean?
---@param limit number?
function Lpdb.executeMassQuery(tableName, queryParameters, itemChecker, limit)
	queryParameters.offset = queryParameters.offset or 0
	queryParameters.limit = queryParameters.limit or MAXIMUM_QUERY_LIMIT
	limit = limit or math.huge

	while queryParameters.offset < limit do
		queryParameters.limit = math.min(queryParameters.limit, limit - queryParameters.offset)

		local lpdbData = mw.ext.LiquipediaDB.lpdb(tableName, queryParameters)
		assert(type(lpdbData) == 'table', lpdbData)
		for _, value in ipairs(lpdbData) do
			if itemChecker(value) == false then
				return
			end
		end

		queryParameters.offset = queryParameters.offset + #lpdbData
		if #lpdbData < queryParameters.limit then
			break
		end
	end
end

--- LPDB Object-Relational Mapping

---@alias ModelColumnData {name: string, fieldType: string|any, default: any}

---@class Model
---@field tableName string
---@field tableColumns ModelColumnData[]
local Model = Class.new(function(self, name, columns)
	self.tableName = name
	self.tableColumns = columns
end)

---@class ModelRow
---@field private tableName string
---@field private tableColumns ModelColumnData[]
---@field private fields table<string, any>
---@field [any] any
local ModelRow = Class.new(function(self, tableName, tableColumns)
	rawset(self, 'tableName', tableName)
	rawset(self, 'tableColumns', tableColumns)
	rawset(self, 'fields', {})
end)

---@param initData table?
---@return ModelRow
function Model:new(initData)
	local row = ModelRow(self.tableName, self.tableColumns)
	if type(initData) == 'table' then
		row:setMany(initData)
	end
	return row
end

---@private
---@param columnData ModelColumnData
function ModelRow:_validateField(columnData)
	if not self.fields[columnData.name] then
		error(self.tableName .. ' expects ' .. columnData.name .. ' to be set')
	end
	-- TODO: Verify types (at least when running tests)
end

---@private
---@param columnData ModelColumnData
function ModelRow:_prepareFieldForStorage(columnData)
	-- Apply defaults
	if not self.fields[columnData.name] then
		if type(columnData.default) == 'function' then
			self.fields[columnData.name] = columnData.default(self.fields)
		else
			self.fields[columnData.name] = columnData.default
		end
	end

	-- Validate that all fields are correct
	self:_validateField(columnData)
end

---@return self
function ModelRow:save()
	Array.forEach(self.tableColumns, FnUtil.curry(ModelRow._prepareFieldForStorage, self))
	local objectName = Table.extract(self.fields, 'objectname')
	mw.ext.LiquipediaDB['lpdb_' .. self.tableName](objectName, self.fields)
	return self
end

---@param key string
---@param value any
function ModelRow:__newindex(key, value)
	if key ~= 'extradata' then
		-- Strip HTML from strings
		-- We allow HTML in extradata though
		local function stripHtml(str)
			if type(str) == 'string' then
				return TextSanitizer.stripHTML(str)
			end
			return str
		end

		if type(value) == 'table' then
			value = Table.mapValues(value, stripHtml)
		else
			value = stripHtml(value)
		end
	end

	self.fields[key] = value
end

function ModelRow:__index(key)
	return ModelRow[key] or rawget(self, 'fields')[key]
end

---@param key string
---@param value any
---@return self
function ModelRow:set(key, value)
	self[key] = value
	return self
end

---@param tbl table<string, any>
---@return self
function ModelRow:setMany(tbl)
	Table.iter.forEachPair(tbl, FnUtil.curry(ModelRow.set, self))
	return self
end

---@class Match2Model:Model
Lpdb.Match2 = Model('match2', {
	{
		name = 'objectname',
		fieldType = 'string',
		default = function(fields)
			return fields.match2id
		end
	},
	{name = 'match2id', fieldType = 'string'},
	{name = 'match2bracketid', fieldType = 'string'},
	{name = 'winner', fieldType = 'string', default = ''},
	{name = 'finished', fieldType = 'number', default = 0},
	{name = 'mode', fieldType = 'string', default = ''},
	{name = 'type', fieldType = 'string', default = ''},
	{name = 'section', fieldType = 'string', default = ''},
	{name = 'game', fieldType = 'string', default = ''},
	{name = 'patch', fieldType = 'string', default = ''},
	{name = 'date', fieldType = 'string', default = 0},
	{name = 'dateexact', fieldType = 'number', default = 0},
	{name = 'stream', fieldType = 'struct', default = {}},
	{name = 'links', fieldType = 'struct', default = {}},
	{name = 'bestof', fieldType = 'number', default = 0},
	{name = 'vod', fieldType = 'string', default = ''},
	{name = 'tournament', fieldType = 'string', default = ''},
	{name = 'parent', fieldType = 'pagename', default = ''},
	{name = 'tickername', fieldType = 'string', default = ''},
	{name = 'shortname', fieldType = 'string', default = ''},
	{name = 'series', fieldType = 'string', default = ''},
	{name = 'icon', fieldType = 'string', default = ''},
	{name = 'icondark', fieldType = 'string', default = ''},
	{name = 'liquipediatier', fieldType = 'string|number', default = ''},
	{name = 'liquipediatiertype', fieldType = 'string', default = ''},
	{name = 'publishertier', fieldType = 'string', default = ''},
	{name = 'extradata', fieldType = 'struct', default = {}},
	{name = 'match2bracketdata', fieldType = 'struct', default = {}},
	{name = 'match2opponents', fieldType = 'array', default = {}},
	{name = 'match2games', fieldType = 'array', default = {}},
})

---@class PlacementModel:Model
Lpdb.Placement = Model('placement', {
	{name = 'objectname', fieldType = 'string'},
	{name = 'tournament', fieldType = 'string', default = ''},
	{name = 'series', fieldType = 'string', default = ''},
	{name = 'parent', fieldType = 'pagename', default = ''},
	{name = 'shortname', fieldType = 'string', default = ''},
	{name = 'startdate', fieldType = 'string', default = 0},
	{name = 'date', fieldType = 'string', default = 0},
	{name = 'placement', fieldType = 'string', default = ''},
	{name = 'prizemoney', fieldType = 'number', default = 0},
	{name = 'individualprizemoney', fieldType = 'number', default = 0},
	{name = 'prizepoolindex', fieldType = 'number'},
	{name = 'weight', fieldType = 'number', default = 0},
	{name = 'mode', fieldType = 'string', default = ''},
	{name = 'type', fieldType = 'string', default = ''},
	{name = 'liquipediatier', fieldType = 'string|number', default = ''},
	{name = 'liquipediatiertype', fieldType = 'string', default = ''},
	{name = 'publishertier', fieldType = 'string', default = ''},
	{name = 'icon', fieldType = 'string', default = ''},
	{name = 'icondark', fieldType = 'string', default = ''},
	{name = 'game', fieldType = 'string', default = ''},
	{name = 'lastvsdata', fieldType = 'struct', default = {}},
	{name = 'opponentname', fieldType = 'string', default = ''},
	{name = 'opponenttemplate', fieldType = 'string', default = ''},
	{name = 'opponenttype', fieldType = 'string', default = ''},
	{name = 'opponentplayers', fieldType = 'struct', default = {}},
	{name = 'qualifier', fieldType = 'string', default = ''},
	{name = 'qualifierpage', fieldType = 'string', default = ''},
	{name = 'qualifierurl', fieldType = 'string', default = ''},
	{name = 'extradata', fieldType = 'struct', default = {}},
})

---@class SquadPlayerModel:Model
Lpdb.SquadPlayer = Model('squadplayer', {
	{
		name = 'objectname',
		fieldType = 'string',
		default = function(fields)
			return fields.link .. '_' .. (fields.joindate or '') .. '_' .. (fields.role or '') .. '_' .. (fields.status or '')
		end
	},
	{name = 'id', fieldType = 'string'},
	{name = 'link', fieldType = 'string'},
	{name = 'name', fieldType = 'string', default = ''},
	{name = 'nationality', fieldType = 'string', default = ''},
	{name = 'position', fieldType = 'string', default = ''},
	{name = 'role', fieldType = 'string', default = ''},
	{name = 'type', fieldType = 'string', default = 'player'},
	{name = 'newteam', fieldType = 'string', default = ''},
	{name = 'teamtemplate', fieldType = 'string', default = ''},
	{name = 'newteamtemplate', fieldType = 'string', default = ''},
	{name = 'status', fieldType = 'string'},
	{name = 'joindate', fieldType = 'string', default = ''},
	{name = 'leavedate', fieldType = 'string', default = ''},
	{name = 'inactivedate', fieldType = 'string', default = ''},
	{name = 'extradata', fieldType = 'struct', default = {}},
})

---@class DataPoint:Model
Lpdb.DataPoint = Model('datapoint', {
	{name = 'objectname', fieldType = 'string'},
	{name = 'type', fieldType = 'string', default = ''},
	{name = 'name', fieldType = 'string', default = ''},
	{name = 'information', fieldType = 'string', default = ''},
	{name = 'image', fieldType = 'string', default = ''},
	{name = 'imagedark', fieldType = 'string', default = ''},
	{name = 'date', fieldType = 'string', default = 0},
	{name = 'extradata', fieldType = 'struct', default = {}},
})

return Lpdb
