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

local _lpdb = {
	lpdb = mw.ext.LiquipediaDB.lpdb
}

function mockLpdb.setUp()
	mw.ext.LiquipediaDB.lpdb = mockLpdb.query
end

function mockLpdb.tearDown()
	mw.ext.LiquipediaDB.lpdb = _lpdb.lpdb
end

--- Not yet support in Mock is:
---- conditions with `OR` or `_`
---- query with `::`
---- order
---- groupby
function mockLpdb.query(table, parameters)
	local data = lpdbData[table]

	if not data then
		return error(mw.message.new('liquipediadb-error-invalid-datatype'))
	end

	data = Array.map(data, function(entry)
		return (Json.parseIfString(entry))
	end)

	-- Conditions
	if String.isNotEmpty(parameters.conditions) then
		local condition = mockLpdb._parseConditions(parameters.conditions)
		data = Array.filter(data, condition)
	end

	--Limit/Offset
	parameters.limit = tonumber(parameters.limit) or 20
	parameters.offset = tonumber(parameters.offset) or 0
	data = Array.sub(data, parameters.offset + 1, (parameters.offset + parameters.limit))

	--Query
	if String.isNotEmpty(parameters.query) then
		local fields = Table.mapValues(mw.text.split(parameters.query, ','), mw.text.trim)
		data = Array.map(data, function(entry)
			return Table.map(entry, function(field, value)
				-- Use map as a filter since there's no applicable filter function atm
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
