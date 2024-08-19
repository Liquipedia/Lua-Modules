---
-- @Liquipedia
-- wiki=commons
-- page=Module:Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = {}

---@deprecated
---Use Array.randomize
function Table.randomize(tbl)
	return require('Module:Array').randomize(tbl)
end

---Get the size of a table
---@param tbl table
---@return integer
function Table.size(tbl)
	local i = 0
	for _ in pairs(tbl) do
		i = i + 1
	end
	return i
end

---@param tbl table
---@param value any
---@param isPattern boolean?
---@return boolean
function Table.includes(tbl, value, isPattern)
	for _, entry in pairs(tbl) do
		if isPattern and string.find(entry, value)
			or not isPattern and entry == value then
				return true
		end
	end
	return false
end

---@generic K, V, T
---@param tbl {[K]: V}
---@param predicate fun(value?: V, argument?: T): boolean
---@param argument T?
---@return {[K]: V}
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

---@generic K, V
---@param tbl {[K]: V}
---@param predicate fun(key?: K, value?: V): boolean
---@return {[K]: V}
function Table.filterByKey(tbl, predicate)
	local filteredTbl = {}

	for key, entry in pairs(tbl) do
		if predicate(key, entry) then
			filteredTbl[key] = entry
		end
	end

	return filteredTbl
end

---Return true if table is empty or nil
---@param tbl table?
---@return boolean
function Table.isEmpty(tbl)
	if tbl == nil then
		return true
	end
	-- luacheck: push ignore
	--it is intended that the loop is executed at most once
	for _, _ in pairs(tbl) do
		return false
	end
	-- luacheck: pop
	return true
end

---Return true if table is neither empty nor nil
---@param tbl table?
---@return boolean
function Table.isNotEmpty(tbl)
	return not Table.isEmpty(tbl)
end

---Shallow copies a table
---@generic T:table
---@param tbl T
---@return T
function Table.copy(tbl)
	local result = {}

	for key, entry in pairs(tbl) do
		result[key] = entry
	end

	return result
end

---Recursively copies a table.
---
---Specifically: for each entry, the value is deep copied and the key is not.
---Entries provided by the __pairs metamethod are copied. Metatables are not
---copied (unless enabled by options.copyMetatable).
---
---options.copyMetatable
---If enabled, deep copies the metatable of tables. Disabled by default.
---
---options.reuseRef
---If a table reference exists at two locations in the input, then this option
---will allow the locations to share a reference in the output. Enabled by default.
---@param tbl_ table
---@param options? {copyMetatable: boolean, reuseRef: boolean}
---@return table
function Table.deepCopy(tbl_, options)
	options = options or {}
	assert(type(tbl_) == 'table', 'Table.deepCopy: Input must be a table')

	local function deepCopy(tbl)
		local result = {}

		for key, value in pairs(tbl) do
			result[key] = type(value) == 'table'
				and deepCopy(value)
				or value
		end

		if options.copyMetatable then
			local metatable = getmetatable(tbl)
			if type(metatable) == 'table' then
				setmetatable(result, deepCopy(metatable))
			end
		end

		return result
	end

	if options.reuseRef ~= false then
		local FnUtil = require('Module:FnUtil')
		deepCopy = FnUtil.memoize(deepCopy)
	end

	return deepCopy(tbl_)
end

---Determines whether two tables are equal, by comparing their entries. Table
---values are compared recursively.
---@param xTable table
---@param yTable table
---@return boolean
function Table.deepEquals(xTable, yTable)
	local Logic = require('Module:Logic')

	assert(type(xTable) == 'table', 'Table.deepEquals: First argument must be a table')
	assert(type(yTable) == 'table', 'Table.deepEquals: Second argument must be a table')

	for key, value in pairs(xTable) do
		if not Logic.deepEquals(value, yTable[key]) then
			return false
		end
	end

	for key, _ in pairs(yTable) do
		if xTable[key] == nil then
			return false
		end
	end

	return true
end

---
---Copies entries from the second table into the first table, overriding existing
---entries. The first table is mutated in the process.
---
---Can be called with more than two tables. The additional tables are merged into
---the first table in succession.
---@param target table
---@param ... table
---@return table
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

---Creates a table with entries merged from the input tables, with entries from
---the later tables given precedence. Input tables are not mutated.
---@param ... table
---@return table
function Table.merge(...)
	return Table.mergeInto({}, ...)
end

--[[
Recursively merges entries from the second table into the first table,
overriding existing entries. The first table is mutated in the process.

Can be called with more than two tables. The additional tables are merged into
the first table in succession. All tables except the last table may be mutated.

Example:
Table.deepMergeInto({a = {x = 3, y = 4}}, {a = {y = 5}})

-- Returns {a = {x = 3, y = 5}}
]]
---@param target table
---@param ... table
---@return table
function Table.deepMergeInto(target, ...)
	local tbls = Table.pack(...)

	for i = 1, tbls.n do
		if type(tbls[i]) == 'table' then
			for key, value in pairs(tbls[i]) do
				if type(target[key]) == 'table' and type(value) == 'table' then
					Table.deepMergeInto(target[key], value)
				else
					target[key] = value
				end
			end
		end
	end
	return target
end

---@param ... table
---@return table
function Table.deepMerge(...)
	return Table.deepMergeInto({}, ...)
end

---Applies a function to each entry in a table and places the results as entries
--in a new table.
--
--Example:
--`Table.map({a = 3, b = 4, c = 5}, function(k, v) return 2 * v, k end)`
--Returns `{6 = 'a', 8 = 'b', 10 = 'c'}`
---@generic K, V, U, T
---@param xTable {[K] : V}
---@param f fun(key?: K, value?: V): U, T
---@return {[U] : T}
function Table.map(xTable, f)
	local yTable = {}
	for xKey, xValue in pairs(xTable) do
		local yKey, yValue = f(xKey, xValue)
		yTable[yKey] = yValue
	end
	return yTable
end

--[[
Extracts prefixed keys interleaved with numeric indexes from an arguments
table, and applies a transform to each key or index.

Used for template calls that support both prefixed and indexed params. See
Module:ParticipantTable/Starcraft, Module:GroupTableLeague for examples of how
it is used.

Example:
In the template call
{{Foo
	|A
	|p2=B
	|C
	|player4=D
}}

Table.mapArgumentsByPrefix(args, {'p', 'player'}, f)
will invoke

f(1, 1)
f('p2', 2, 'p')
f(2, 3)
f('player4', 4, 'player')

]]
---@generic K, V, T, I
---@param args {[K] : V}
---@param prefixes string[]
---@param f function
---@return {[I] : T}
function Table.mapArgumentsByPrefix(args, prefixes, f)
	local function indexFromKey(key)
		local prefix, index = key:match('^([%a_]+)(%d+)$')
		if Table.includes(prefixes, prefix) then
			return tonumber(index), prefix
		else
			return nil
		end
	end

	return Table.mapArguments(args, indexFromKey, f)
end

--- Extracts keys based on a passed `indexFromKey` function interleaved with numeric indexes
-- from an arguments table, and applies a transform to each key or index.
--
-- Most common use-case will be `Table.mapArgumentsByPrefix` where
-- the `indexFromKey` function retrieves keys based on a prefix.
--
---@generic K, V, T, I
---@param args {[K] : V}
---@param indexFromKey fun(key?: K): integer?
---@param f fun(key?: K, index?: integer, ...?: any): T
---@param noInterleave boolean?
---@return {[I] : T}
function Table.mapArguments(args, indexFromKey, f, noInterleave)
	local entriesByIndex = {}

	-- Non-numeric args
	for key, _ in pairs(args) do
		local function post(index, ...)
			if index and not entriesByIndex[index] then
				entriesByIndex[index] = f(key, index, ...)
			end
		end
		if type(key) == 'string' then
			post(indexFromKey(key))
		end
	end

	if noInterleave then
		return entriesByIndex
	end

	-- Numeric index entries fills in gaps of prefixN= entries if not disabled
	local entryIndex = 1
	for argIndex = 1, math.huge do
		if not args[argIndex] then
			break
		end
		while entriesByIndex[entryIndex] do
			entryIndex = entryIndex + 1
		end
		entriesByIndex[entryIndex] = f(argIndex, entryIndex)
	end

	return entriesByIndex
end

---Applies a function to each value in a table and places the results in a new
--table under the same keys.
--
--Example:
--`Table.mapValues({1, 2, 3}, function(x) return 2 * x end)`
--Returns `{2, 4, 6}`
--
--The return is not parsed correctly yet by extension, https://github.com/sumneko/lua-language-server/issues/1535
---@generic K, V, T
---@param xTable {[K] : V}
---@param f fun(value?: V): T
---@return {[K] : T}
function Table.mapValues(xTable, f)
	local yTable = {}
	for xKey, xValue in pairs(xTable) do
		yTable[xKey] = f(xValue)
	end
	return yTable
end

---Whether all entries of a table satisfy a predicate.
---@generic K, V
---@param tbl {[K] : V}
---@param predicate fun(key?: K, value?: V): boolean
---@return boolean
function Table.all(tbl, predicate)
	for key, value in pairs(tbl) do
		if not predicate(key, value) then
			return false
		end
	end
	return true
end

---Whether any entry of a table satisfies a predicate.
---@generic K, V
---@param tbl {[K] : V}
---@param predicate fun(key?: K, value?: V): boolean
---@return boolean
function Table.any(tbl, predicate)
	for key, value in pairs(tbl) do
		if predicate(key, value) then
			return true
		end
	end
	return false
end

--[[
Groups entries of a table according to a grouping function.

Example:
local function parity(_, x) return x % 2 end
Table.groupBy({a = 3, b = 4, c = 5}, parity)
-- Returns
{
	0 = {b = 4},
	1 = {a = 3, c = 5},
}
]]
---@generic K, V, T
---@param tbl {[K] : V}
---@param f fun(key?: K, value?: V): T
---@return {[T] : {[K]: V}}
function Table.groupBy(tbl, f)
	local groups = {}
	for key, value in pairs(tbl) do
		local groupKey = f(key, value)
		if not groups[groupKey] then
			groups[groupKey] = {}
		end
		groups[groupKey][key] = value
	end
	return groups
end

---Removes a key from a table and returns its value.
---@generic K, V
---@param tbl table<K, V>
---@param key K
---@return V
function Table.extract(tbl, key)
	local value = tbl[key]
	tbl[key] = nil
	return value
end

---@param tbl table
---@param path any[]
---@return any?
function Table.getByPathOrNil(tbl, path)
	for _, fieldName in ipairs(path) do
		if type(tbl) ~= 'table' then
			return nil
		end
		tbl = tbl[fieldName]
	end
	return tbl
end

---@param tbl table
---@param path any[]
---@param value any
function Table.setByPath(tbl, path, value)
	for i = 1, #path - 1 do
		if tbl[path[i]] == nil then
			tbl[path[i]] = {}
		end
		tbl = tbl[path[i]]
	end
	tbl[path[#path]] = value
end

---Returns the unique key in a table. Returns nil if the table is empty or has multiple keys.
---@generic K, V
---@param tbl {[K]: V}
---@return K?
function Table.uniqueKey(tbl)
	local key0 = nil
	for key, _ in pairs(tbl) do
		if key0 ~= nil then return nil end
		key0 = key
	end
	return key0
end

---Returns the entries of a table as an array of key value pairs. The ordering of the array is not specified.
---@generic K, V
---@param tbl {[K]: V}
---@return {[1]: K, [2]: V}[]
function Table.entries(tbl)
	local entries = {}
	for key, value in pairs(tbl) do
		table.insert(entries, {key, value})
	end
	return entries
end

-- Polyfill of lua 5.2 table.pack
---@generic V
---@param ... V
---@return {n: integer, value...: V}
function Table.pack(...)
	return {n = select('#', ...), ...}
end

--
-- iterator functions
--
Table.iter = {}

-- iterate over table in a sorted order
---@generic K, V
---@param tbl {[K]: V}
---@param order? fun(tbl: table, a: K, b: K): boolean
---@return function
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

--[[
Iterates over table entries whose keys are prefixed numbers. The entries are
visited in order, starting from 1. The iteration stops upon a skipped number.
If requireIndex is disabled, for the first entry, both `prefix` and `prefix1`
are valid keys, with a preference for the latter.

Example:
```
local args = {
	p = {},
	p1 = {},
	p2 = {},
	p3 = {},
	foo = {},
	p10 = {},
}
for key, player, index in Table.iter.pairsByPrefix(args, 'p') do
	mw.log(key)
end
```
will print out `p1 p2 p3`
]]
---@param tbl table
---@param prefixes string|string[]
---@param options? {requireIndex: boolean}
---@return fun(): string?, any?, integer?
function Table.iter.pairsByPrefix(tbl, prefixes, options)
	options = options or {}

	if type(prefixes) == 'string' then
		prefixes = {prefixes}
	end

	local getByPrefixes = function(index)
		for _, prefix in ipairs(prefixes) do
			local key = prefix .. index
			if tbl[key] then
				return key, tbl[key]
			end
		end
	end

	local i = 1
	return function()
		local key, value = getByPrefixes(i)
		if options.requireIndex == false and i == 1 and not value then
			key, value = getByPrefixes('')
		end
		i = i + 1
		if value then
			return key, value, (i - 1)
		else
			return nil
		end
	end
end

---@deprecated Use Array.forEach
---@generic V
---@param tbl V[]
---@param lambda fun(item: V)
function Table.iter.forEach(tbl, lambda)
	for _, item in ipairs(tbl) do
		lambda(item)
	end
end

---@deprecated Use Array.forEach
---@generic V
---@param tbl V[]
---@param lambda fun(index: integer, item: V)
function Table.iter.forEachIndexed(tbl, lambda)
	for index, item in ipairs(tbl) do
		lambda(index, item)
	end
end

---@generic K, V
---@param tbl {[K]: V}
---@param lambda fun(key: K, val: V?)
function Table.iter.forEachPair(tbl, lambda)
	for key, val in pairs(tbl) do
		lambda(key, val)
	end
end

return Table
