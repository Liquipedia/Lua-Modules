---
-- @Liquipedia
-- wiki=commons
-- page=Module:Mock/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local lpdbData = Lua.import('Module:Mock/Lpdb/Data', {requireDevIfEnabled = true})

local mockLpdb = {}

local DEFAULTS = {
	limit = 20,
	offset = 0,
}

local _lpdb = {
	lpdb = mw.ext.LiquipediaDB.lpdb
}

function mockLpdb.setUp()
	mw.ext.LiquipediaDB.lpdb = mockLpdb.lpdb
end

function mockLpdb.tearDown()
	mw.ext.LiquipediaDB.lpdb = _lpdb.lpdb
end

--- Not yet support in Mock is:
---- conditions with `OR` or `_`
---- query with `::`
---- order
---- groupby
function mockLpdb.lpdb(dbTable, parameters)
	local returnedData = mockLpdb._getMockData(dbTable)

	returnedData = mockLpdb._applyConditionse(returnedData, parameters.conditions)

	returnedData = mockLpdb._applyLimitOffset(returnedData, parameters.limit, parameters.offset)

	returnedData = mockLpdb._applyQuery(returnedData, parameters.query)

	return returnedData
end

function mockLpdb._getMockData(dbTable)
	local data = lpdbData[dbTable]

	if not data then
		return error(mw.message.new('liquipediadb-error-invalid-datatype'))
	end

	return Array.map(data, function(entry)
		local parsedData = Json.parseIfString(entry)
		return parsedData
	end)
end

function mockLpdb._applyConditionse(data, conditions)
	if String.isNotEmpty(conditions) then
		local condition = mockLpdb._parseConditions(conditions)
		return Array.filter(data, condition)
	end

	return data
end

function mockLpdb._applyLimitOffset(data, limit, offset)
	local limit = tonumber(limit) or DEFAULTS.limit
	local offset = tonumber(offset) or DEFAULTS.offset

	return Array.sub(data, offset + 1, (offset + limit))
end

function mockLpdb._applyQuery(data, query)
	if String.isNotEmpty(query) then
		local fields = Table.mapValues(mw.text.split(query, ','), mw.text.trim)

		return Array.map(data, function(entry)
			return Table.map(entry, function(field, value)
				-- Use map as a filter since there's no applicable filter function in either Array or Table yet
				return field, Table.includes(fields, field) and value or nil
			end)
		end)
	end

	return data
end

function mockLpdb._parseConditions(conditions)
	---@type {comparator:string, name:string, value:string}[]
	local criterias = {}

	for name, comparator, value in string.gmatch(conditions, '%[%[(%a+)::([!><]?)([%a%s%d]+)]]') do
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

return mockLpdb
