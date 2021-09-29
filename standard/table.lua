---
-- @Liquipedia
-- wiki=commons
-- page=Module:Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---
-- @author Vogan for Liquipedia
--
-- A number of these functions take inspiration from Penlight: https://github.com/lunarmodules/Penlight
--

local Class = require('Module:Class')

local Table = {}

function Table.randomize(tbl)
	math.randomseed(os.time())

	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function Table.size(tbl)
	local i = 0
	for _ in pairs(tbl) do
		i = i + 1
	end
	return i
end

function Table.includes(tbl, value)
	for _, entry in ipairs(tbl) do
		if entry == value then
			return true
		end
	end
	return false
end

function Table.filter(tbl, predicate, argument)
	local filteredTbl = {}
	local foundMatches = 1

	for _, entry in pairs(tbl) do
		if predicate(entry, argument) then
			filteredTbl[foundMatches] = entry
			foundMatches = foundMatches + 1
		end
	end

	return filteredTbl
end

function Table.isEmpty(tbl)
	if tbl == nil then
		return true
	end
	for _, _ in pairs(tbl) do
		return false
	end
	return true
end

function Table.copy(tbl)
	local result = {}

	for key, entry in pairs(tbl) do
		result[key] = entry
	end

	return result
end

function Table.deepCopy(tbl)
	return mw.clone(tbl)
end

--[[
Copies entries from the second table into the first table, overriding existing 
entries. The first table is mutated in the process.

Can be called with more than two tables. The additional tables are merged into 
the first table in succession.
]]
function Table.mergeInto(target, ...)
	local objs = Table.pack(...)
	for i = 1, objs.n do
		if type(objs[i]) == 'table' then
			for key, value in pairs(objs[i]) do
				target[key] = value
			end
		end
	end
	return target
end

--[[
Creates a table with entries merged from the input tables, with entries from 
the later tables given precedence. Input tables are not mutated.
]]
function Table.merge(...)
	return Table.mergeInto({}, ...)
end

--[[
Applies a function to each entry in a table and places the results as entries 
in a new table.

Example:
Table.map({a = 3, b = 4, c = 5}, function(k, v) return 2 * v, k end)
-- Returns {6 = 'a', 8 = 'b', 10 = 'c'}
]]
function Table.map(xTable, f)
	local yTable = {}
	for xKey, xValue in pairs(xTable) do
		local yKey, yValue = f(xKey, xValue)
		yTable[yKey] = yValue
	end
	return yTable
end

--[[
Applies a function to each value in a table and places the results in a new 
table under the same keys.

Example:
Table.mapValues({1, 2, 3}, function(x) return 2 * x end)
-- Returns {2, 4, 6}
]]
function Table.mapValues(xTable, f)
	local yTable = {}
	for xKey, xValue in pairs(xTable) do
		yTable[xKey] = f(xValue)
	end
	return yTable
end

--[[
Whether all entries of a table satisfy a predicate.
]]
function Table.all(tbl, predicate)
	for key, value in pairs(tbl) do
		if not predicate(key, value) then
			return false
		end
	end
	return true
end

--[[
Whether any entry of a table satisfies a predicate.
]]
function Table.any(tbl, predicate)
	for key, value in pairs(tbl) do
		if predicate(key, value) then
			return true
		end
	end
	return false
end

-- Removes a key from a table and returns its value.
function Table.extract(tbl, key)
	local value = tbl[key]
	tbl[key] = nil
	return value
end

function Table.getByPath(tbl, path)
	for _, fieldName in ipairs(path) do
		tbl = tbl[fieldName]
	end
	return tbl
end

function Table.getByPathOrNil(tbl, path)
	for _, fieldName in ipairs(path) do
		if type(tbl) ~= 'table' then
			return nil
		end
		tbl = tbl[fieldName]
	end
	return tbl
end

function Table.setByPath(tbl, path, value)
	for i = 1, #path - 1 do
		if tbl[path[i]] == nil then
			tbl[path[i]] = {}
		end
		tbl = tbl[path[i]]
	end
	tbl[path[#path]] = value
end

--[[
Returns the unique key in an table. Returns nil if the table is empty or has
multiple keys.
]]
function Table.uniqueKey(tbl)
	local key0 = nil
	for key, _ in pairs(tbl) do
		if key0 ~= nil then return nil end
		key0 = key
	end
	return key0
end

-- Polyfill of lua 5.2 table.pack
function Table.pack(...)
	return {n = select('#', ...), ...}
end

--
-- iterator functions
--
Table.iter = {}

-- iterate over table in a sorted order
function Table.iter.spairs(tbl, order)
	-- collect the keys
	local keys = {}
	for k in pairs(tbl) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if order then
		table.sort(keys, function(a,b) return order(tbl, a, b) end)
	else
		table.sort(keys)
	end

	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], tbl[keys[i]]
		end
	end
end

function Table.iter.forEach(tbl, lambda)
	for index, item in ipairs(tbl) do
		lambda(item)
	end
end

function Table.iter.forEachIndexed(tbl, lambda)
	for index, item in ipairs(tbl) do
		lambda(index, item)
	end
end

function Table.iter.forEachPair(tbl, lambda)
	for key, val in pairs(tbl) do
		lambda(key, val)
	end
end

return Table
