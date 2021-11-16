---
-- @Liquipedia
-- wiki=commons
-- page=Module:Array
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')

--
-- Array functions. Arrays are tables with numeric indexes that does not
-- have gaps. Functions in Array use ipairs() to iterate over tables.
--
-- For functions using pairs() instead of ipairs(), use Module:Table.
--
local Array = {}

function Array.randomize(tbl)
	return Table.randomize(tbl)
end

-- Creates a copy of an array with the same elements.
function Array.copy(tbl)
	local out_tbl = {}
	for _, x in ipairs(tbl) do
		table.insert(out_tbl, x)
	end
	return out_tbl
end

--[[
Returns a subarray given by its indexes.

Examples
Array.sub({3, 5, 7, 11}, 2) -- returns {5, 7, 11}
Array.sub({3, 5, 7, 11}, 2, 3) -- returns {5, 7}
Array.sub({3, 5, 7, 11}, -2, -1) -- returns {7, 11}
]]
function Array.sub(tbl, a, b)
	if a < 0 then a = #tbl + 1 + a end
	if not b then b = #tbl end
	if b < 0 then b = #tbl + 1 + b end

	local out_tbl = {}
	for i = a, b do
		table.insert(out_tbl, tbl[i])
	end
	return out_tbl
end

--[[
Applies a function to each element in an array and places the results in a
new array.

Example:
Array.map({1, 2, 3}, function(x) return 2 * x end)
-- returns {2, 4, 6}
]]
function Array.map(elems, f)
	local outElems = {}
	for index, elem in ipairs(elems) do
		table.insert(outElems, f(elem, index))
	end
	return outElems
end

--[[
Filters an array based on a predicate.

Example:
Array.filter({1, 2, 3}, function(x) return x % 2 == 1 end)
-- returns {1, 3}
]]
function Array.filter(tbl, pred)
	local out_tbl = {}
	for i, x in ipairs(tbl) do
		if pred(x, i) then
			table.insert(out_tbl, x)
		end
	end
	return out_tbl
end

--[[
Flattens an array of arrays into an array.
]]
function Array.flatten(tbl)
	local out_tbl = {}
	for _, x in ipairs(tbl) do
		if type(x) == 'table' then
			for _, y in ipairs(x) do
				table.insert(out_tbl, y)
			end
		else
			table.insert(out_tbl, x)
		end
	end
	return out_tbl
end

function Array.flatMap(tbl, f)
	return Array.flatten(Array.map(tbl, f))
end

--[[
Whether all elements in an array satisfy a predicate.
]]
function Array.all(tbl, predicate)
	for _, elem in ipairs(tbl) do
		if not predicate(elem) then
			return false
		end
	end
	return true
end

--[[
Whether any elements in an array satisfies a predicate.
]]
function Array.any(tbl, predicate)
	for _, elem in ipairs(tbl) do
		if predicate(elem) then
			return true
		end
	end
	return false
end

--[[
Finds the first element in an array satisfying a predicate. Returs nil if no
element satisfies the predicate.
]]
function Array.find(tbl, pred)
	for ix, x in ipairs(tbl) do
		if pred(x, ix) then
			return x
		end
	end
	return nil
end

--[[
Groups an array based on applying a transformation to the elements.

The function returns two values. The first is an array of groups. The second
is a table whose keys are the transformed values and whose values are the
groups.

Example:
Array.groupBy({2, 3, 5, 7, 11, 13}, function(x) return x % 4 end)
-- returns {{2}, {3, 7, 11}, {5, 13}},
-- {1 = {5, 13}, 2 = {2}, 3 = {3, 7, 11}}
]]
function Array.groupBy(tbl, f)
	local groupsByKey = {}
	local groups = {}
	for _, x in ipairs(tbl) do
		local y = f(x)
		local group = groupsByKey[y]
		if not group then
			group = {}
			groupsByKey[y] = group
			table.insert(groups, group)
		end
		table.insert(group, x)
	end

	return groups, groupsByKey
end

-- Lexicographically compare two arrays.
function Array.lexicalCompare(tblX, tblY)
	for i = 1, math.min(#tblX, #tblY) do
		if tblX[i] < tblY[i] then
			return true
		elseif tblX[i] > tblY[i] then
			return false
		end
	end
	return #tblX < #tblY
end

function Array.lexicalCompareIfTable(y1, y2)
	if type(y1) == 'table' and type(y2) == 'table' then
		return Array.lexicalCompare(y1, y2)
	else
		return y1 < y2
	end
end

--[[
Sorts an array by transforming its elements via a function and comparing the
transformed elements.

If the transformed elements are arrays, then they will be lexically compared.
This is useful for setting up tie-breaker criteria - put the main critera in
the first element, and subsequent tie-breakers in the remaining elements.

The optional third argument specifies a custom comparator for the transformed elements.

Examples:
Array.sortBy({-3, -1, 2, 4}, function(x) return x * x end)
-- returns {-1, 2, -3, 4}

Array.sortBy({
	{first='Neil', last='Armstrong'},
	{first='Louis', last='Armstrong'},
	{first='Buzz', last='Aldrin'},
}, function(x) return {x.last, x.first} end)
-- returns {
--	{first='Buzz', last='Aldrin'},
--	{first='Louis', last='Armstrong'},
--	{first='Neil', last='Armstrong'},
-- }

]]
function Array.sortBy(tbl, f, compare)
	local tbl2 = Table.copy(tbl)
	Array.sortInPlaceBy(tbl2, f, compare)
	return tbl2
end

--[[
Like Array.sortBy, except that it sorts in place. Mutates the first argument.
]]
function Array.sortInPlaceBy(tbl, f, compare)
	compare = compare or Array.lexicalCompareIfTable
	table.sort(tbl, function(x1, x2) return compare(f(x1), f(x2)) end)
end

-- Reverses the order of elements in an array.
function Array.reverse(tbl)
	local out_tbl = {}
	for i = #tbl, 1, -1 do
		table.insert(out_tbl, tbl[i])
	end
	return out_tbl
end

--[[
Returns an array with elements append to the end. Does not mutate the inputs.

Example:
Array.append({2, 3}, 5, 7, 11)
-- returns {2, 3, 5, 7, 11}
]]
function Array.append(tbl, ...)
	return Array.appendWith(Array.copy(tbl), ...)
end

--[[
Adds elements to the end of an array. The array is mutated in the process.
]]
function Array.appendWith(tbl, ...)
	local elems = Table.pack(...)
	for i = 1, elems.n do
		if elems[i] ~= nil then
			table.insert(tbl, elems[i])
		end
	end
	return tbl
end

--[[
Returns an array with elements from one or more arrays append to the end. Does
not mutate the inputs.

Example:
Array.extend({2, 3}, {5, 7, 11}, {13})
-- returns {2, 3, 5, 7, 11, 13}

Array.extend({2, 3}, 5, 7, nil, {11, 13})
-- returns {2, 3, 5, 7, 11, 13}
]]
function Array.extend(tbl, ...)
	return Array.extendWith({}, tbl, ...)
end

--[[
Adds elements from one or more arrays to the end of a target array. The target
array is mutated in the process.
]]
function Array.extendWith(tbl, ...)
	local arrays = Table.pack(...)
	for i = 1, arrays.n do
		if type(arrays[i]) == 'table' then
			for _, elem in ipairs(arrays[i]) do
				table.insert(tbl, elem)
			end
		elseif arrays[i] ~= nil then
			table.insert(tbl, arrays[i])
		end
	end
	return tbl
end

--[[
Returns the array {f(1), f(2), f(3), ...}. Stops before the first nil value returned by f.

Example:
Array.mapIndexes(function(x) return x < 5 and x * x or nil end)
-- returns {1, 4, 9, 16}
]]
function Array.mapIndexes(f)
	local arr = {}
	for i = 1, math.huge do
		local y = f(i)
		if y then
			table.insert(arr, y)
		else
			break
		end
	end
	return arr
end

--[[
Returns the array {from, from + 1, from + 2, ..., to}.
]]
function Array.range(from, to)
	local elems = {}
	for elem = from, to do
		table.insert(elems, elem)
	end
	return elems
end

function Array.extractKeys(tbl)
	local keys = {}
	for key, _ in pairs(tbl) do
		table.insert(keys, key)
	end
	return keys
end

function Array.extractValues(tbl)
	local values = {}
	for _, value in pairs(tbl) do
		table.insert(values, value)
	end
	return values
end

--[[
Applies a function to each element in an array.

Example:

Array.forEach({4, 6, 8}, mw.log)
-- Prints 4 1 6 2 8 3
]]
function Array.forEach(elems, f)
	for i, elem in ipairs(elems) do
		f(elem, i)
	end
end

--[[
Reduces an array using the specified binary operation. Computes
operator(... operator(operator(operator(initialValue, array[1]), array[2]), array[3]), ... array[#array])

If initialValue is not provided then the operator(initialValue, array[1]) step is skipped, and
operator(array[1], array[2]) becomes the first step.

Example:

local function pow(x, y) return x ^ y end
Array.reduce({2, 3, 5}, pow)
-- Returns 32768
]]
function Array.reduce(array, operator, initialValue)
	local aggregate
	if initialValue ~= nil then
		aggregate = initialValue
	else
		aggregate = array[1]
	end

	for i = initialValue ~= nil and 1 or 2, #array do
		aggregate = operator(aggregate, array[i])
	end
	return aggregate
end

--[[
Computes the maximum element in an array according to a scoring function. Returns
nil if the array is empty.
]]
function Array.maxBy(array, f, compare)
	compare = compare or Array.lexicalCompareIfTable

	local max, maxScore
	for _, item in ipairs(array) do
		local score = f(item)
		if max == nil or compare(maxScore, score) then
			max = item
			maxScore = score
		end
	end
	return max
end

--[[
Computes the maximum element in an array. Returns nil if the array is empty.
]]
function Array.max(array, compare)
	return Array.maxBy(array, function(x) return x end, compare)
end

--[[
Computes the minimum element in an array according to a scoring function. Returns
nil if the array is empty.
]]
function Array.minBy(array, f, compare)
	compare = compare or Array.lexicalCompareIfTable

	local min, minScore
	for _, item in ipairs(array) do
		local score = f(item)
		if min == nil or compare(score, minScore) then
			min = item
			minScore = score
		end
	end
	return min
end

--[[
Computes the minimum element in an array. Returns nil if the array is empty.
]]
function Array.min(array, compare)
	return Array.minBy(array, function(x) return x end, compare)
end

return Array
