---
-- @Liquipedia
-- wiki=commons
-- page=Module:Array
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

--
-- Array functions. Arrays are tables with numeric indexes that does not
-- have gaps. Functions in Array use ipairs() to iterate over tables.
--
-- For functions using pairs() instead of ipairs(), use Module:Table.
--
local Array = {}

---Modify an array in-place by shuffling its contents.
---@generic T
---@param tbl T[]
---@return T[]
function Array.randomize(tbl)
	math.randomseed(os.time())

	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

---Return true if the input is a table in array format
---@param tbl any
---@return boolean
function Array.isArray(tbl)
	return type(tbl) == 'table' and Table.size(tbl) == #tbl
end

-- Creates a copy of an array with the same elements.
---@generic T
---@param tbl T[]
---@return T[]
function Array.copy(tbl)
	local copy = {}
	for _, element in ipairs(tbl) do
		table.insert(copy, element)
	end
	return copy
end

--[[
Returns a subarray given by its indexes.

Examples:
Array.sub({3, 5, 7, 11}, 2) = {5, 7, 11};
Array.sub({3, 5, 7, 11}, 2, 3) = {5, 7};
Array.sub({3, 5, 7, 11}, -2, -1) = {7, 11}
]]
---@generic T
---@param tbl T[]
---@param startIndex integer
---@param endIndex integer?
---@return T[]
function Array.sub(tbl, startIndex, endIndex)
	if startIndex < 0 then startIndex = #tbl + 1 + startIndex end
	if not endIndex then endIndex = #tbl end
	if endIndex < 0 then endIndex = #tbl + 1 + endIndex end

	local subArray = {}
	for index = startIndex, endIndex do
		table.insert(subArray, tbl[index])
	end
	return subArray
end

---Applies a function to each element in an array and places the results in a new array.
---@generic V, T
---@param elements V[]
---@param funct fun(element: V, index?: integer): T|nil
---@return T[]
function Array.map(elements, funct)
	local mappedArray = {}
	for index, element in ipairs(elements) do
		table.insert(mappedArray, funct(element, index))
	end
	return mappedArray
end

--[[
Filters an array based on a predicate.

Example:
Array.filter({1, 2, 3}, function(x) return x % 2 == 1 end)
-- returns {1, 3}
]]
---@generic T
---@param tbl T[]
---@param predicate fun(element?: T, index?: integer): boolean
---@return T[]
function Array.filter(tbl, predicate)
	local filteredArray = {}
	for index, element in ipairs(tbl) do
		if predicate(element, index) then
			table.insert(filteredArray, element)
		end
	end
	return filteredArray
end

---Flattens an array of arrays into an array.
---@generic T
---@param tbl T[]
---@return T[]
function Array.flatten(tbl)
	local flattenedArray = {}
	for _, x in ipairs(tbl) do
		if type(x) == 'table' then
			for _, y in ipairs(x) do
				table.insert(flattenedArray, y)
			end
		else
			table.insert(flattenedArray, x)
		end
	end
	return flattenedArray
end

---@generic T
---@param tbl T[]
---@param funct any
---@return T[]
function Array.flatMap(tbl, funct)
	return Array.flatten(Array.map(tbl, funct))
end

---Determnines whether all elements in an array satisfy a predicate.
---@generic T
---@param tbl T[]
---@param predicate fun(element: T): boolean
---@return boolean
function Array.all(tbl, predicate)
	for _, element in ipairs(tbl) do
		if not predicate(element) then
			return false
		end
	end
	return true
end

---Determnines whether any elements in an array satisfies a predicate.
---@generic T
---@param tbl T[]
---@param predicate fun(element: T): boolean
---@return boolean
function Array.any(tbl, predicate)
	for _, element in ipairs(tbl) do
		if predicate(element) then
			return true
		end
	end
	return false
end

---Finds the first element in an array satisfying a predicate. Returs nil if no element satisfies the predicate.
---@generic T
---@param tbl T[]
---@param predicate fun(element?: T, index?: integer): boolean
---@return T?
function Array.find(tbl, predicate)
	for index, element in ipairs(tbl) do
		if predicate(element, index) then
			return element
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
---@generic T, K
---@param tbl T[]
---@param funct fun(xValue: T): K?
---@return T[][]
---@return table<K, T[]>
function Array.groupBy(tbl, funct)
	local groupsByKey = {}
	local groups = {}
	for _, xValue in ipairs(tbl) do
		local yValue = funct(xValue)
		if yValue then
			local group = groupsByKey[yValue]
			if not group then
				group = {}
				groupsByKey[yValue] = group
				table.insert(groups, group)
			end
			table.insert(group, xValue)
		end
	end

	return groups, groupsByKey
end

--[[
Groups adjacent elements of an array based on applying a transformation to the
elements. The function returns an array of groups.

The optional equals parameter specifies the equality relation of the
transformed elements.

Example:
Array.groupAdjacentBy({2, 3, 5, 7, 14, 16}, function(x) return x % 2 end)
-- returns {{2}, {3, 5, 7}, {14, 16}}
]]
---@generic V, T
---@param array V[]
---@param f fun(elem: V): T
---@param equals? fun(key: T, currentKey: T): boolean
---@return V[][]
function Array.groupAdjacentBy(array, f, equals)
	equals = equals or Logic.deepEquals

	local groups = {}
	local currentKey
	for index, elem in ipairs(array) do
		local key = f(elem)
		if index == 1 or not equals(key, currentKey) then
			currentKey = key
			table.insert(groups, {})
		end
		table.insert(groups[#groups], elem)
	end

	return groups
end

---Lexicographically compare two arrays.
---@generic T
---@param tblX T[]
---@param tblY T[]
---@return boolean
function Array.lexicalCompare(tblX, tblY)
	for index = 1, math.min(#tblX, #tblY) do
		if tblX[index] < tblY[index] then
			return true
		elseif tblX[index] > tblY[index] then
			return false
		end
	end
	return #tblX < #tblY
end

---Lexicographically compare 2 values.
---If they are arrays (tables) compare them via `Array.lexicalCompare`.
---Else compare them as directly values.
---@generic T
---@param y1 T[]|T
---@param y2 T[]|T
---@return boolean
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
---@generic T, V
---@param tbl T[]
---@param funct fun(element: T): V
---@param compare? fun(a: V, b: V): boolean
---@return T[]
function Array.sortBy(tbl, funct, compare)
	local copy = Table.copy(tbl)
	Array.sortInPlaceBy(copy, funct, compare)
	return copy
end

---Sorts an array by transforming its elements via a function and comparing the transformed elements.
---Similar to `Array.sortBy` but sorts in place, i.e. mutates the first argument.
---@generic T, V
---@param tbl T[]
---@param funct fun(element: T): V
---@param compare? fun(a: V, b: V): boolean
function Array.sortInPlaceBy(tbl, funct, compare)
	compare = compare or Array.lexicalCompareIfTable
	table.sort(tbl, function(x1, x2) return compare(funct(x1), funct(x2)) end)
end

-- Reverses the order of elements in an array.
---@generic T
---@param tbl T[]
---@return T[]
function Array.reverse(tbl)
	local reversedArray = {}
	for index = #tbl, 1, -1 do
		table.insert(reversedArray, tbl[index])
	end
	return reversedArray
end

--[[
Returns an array with elements append to the end. Does not mutate the inputs.

Example:
Array.append({2, 3}, 5, 7, 11)
-- returns {2, 3, 5, 7, 11}
]]
---@generic T
---@param tbl T[]
---@param ... any
---@return any[]
function Array.append(tbl, ...)
	return Array.appendWith(Array.copy(tbl), ...)
end

---Adds elements to the end of an array. The array is mutated in the process.
---@generic T
---@param tbl T[]
---@param ... any
---@return any[]
function Array.appendWith(tbl, ...)
	local elements = Table.pack(...)
	for index = 1, elements.n do
		if elements[index] ~= nil then
			table.insert(tbl, elements[index])
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
---@generic T
---@param tbl T[]|T
---@param ... T[]|T
---@return T[]
function Array.extend(tbl, ...)
	return Array.extendWith({}, tbl, ...)
end

--[[
Adds elements from one or more arrays to the end of a target array. The target
array is mutated in the process.
]]
---@generic T
---@param tbl T[]
---@param ... T[]|T
---@return T[]
function Array.extendWith(tbl, ...)
	local arrays = Table.pack(...)
	for index = 1, arrays.n do
		if type(arrays[index]) == 'table' then
			for _, element in ipairs(arrays[index]) do
				table.insert(tbl, element)
			end
		elseif arrays[index] ~= nil then
			table.insert(tbl, arrays[index])
		end
	end
	return tbl
end

--[[
Returns the array {funct(1), funct(2), funct(3), ...}. Stops before the first nil value returned by funct.

Example:
Array.mapIndexes(function(x) return x < 5 and x * x or nil end)
-- returns {1, 4, 9, 16}
]]
---@generic T
---@param funct fun(index: integer): T?
---@return T[]
function Array.mapIndexes(funct)
	local arr = {}
	for index = 1, math.huge do
		local y = funct(index)
		if y then
			table.insert(arr, y)
		else
			break
		end
	end
	return arr
end

---Returns the array {from, from + 1, from + 2, ..., to}.
---@param from integer
---@param to integer
---@return integer[]
function Array.range(from, to)
	local elements = {}
	for element = from, to do
		table.insert(elements, element)
	end
	return elements
end

---Extracts keys from a given table into an array. An order can be supplied via an iterator.
---@generic K, V
---@param tbl {[K]: V}
---@param iterator? fun(tbl: table, ...):fun(table: table<K, V>, index?: K):K, V, ...
---@param ... any
---@return K[]
function Array.extractKeys(tbl, iterator, ...)
	iterator = iterator or pairs
	local array = {}
	for key, _ in iterator(tbl, ...) do
		table.insert(array, key)
	end
	return array
end

---Extracts values from a given table into an array. An order can be supplied via an iterator.
---@generic K, V
---@param tbl {[K]: V}
---@param iterator? fun(tbl: table, ...):fun(table: table<K, V>, index?: K):K, V, ...
---@param ... any
---@return V[]
function Array.extractValues(tbl, iterator, ...)
	iterator = iterator or pairs
	local array = {}
	for _, item in iterator(tbl, ...) do
		table.insert(array, item)
	end
	return array
end

--[[
Applies a function to each element in an array.

Example:

Array.forEach({4, 6, 8}, mw.log)
-- Prints 4 1 6 2 8 3
]]
---@generic T
---@param elements T[]
---@param funct fun(element?: T, index?: integer)
function Array.forEach(elements, funct)
	for index, element in ipairs(elements) do
		funct(element, index)
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
---@generic T, V
---@param array T[]
---@param operator fun(aggregate: V, arrayValue: T): V
---@param initialValue V?
---@return V?
function Array.reduce(array, operator, initialValue)
	local aggregate
	if initialValue ~= nil then
		aggregate = initialValue
	else
		aggregate = array[1]
	end

	for index = initialValue ~= nil and 1 or 2, #array do
		aggregate = operator(aggregate, array[index])
	end
	return aggregate
end

---Computes the maximum element in an array according to a scoring function. Returns nil if the array is empty.
---@generic T, V
---@param array T[]
---@param funct fun(item: T): V
---@param compare? fun(maxScore: V, score: V): boolean
---@return V
function Array.maxBy(array, funct, compare)
	compare = compare or Array.lexicalCompareIfTable

	local max, maxScore
	for _, item in ipairs(array) do
		local score = funct(item)
		if max == nil or compare(maxScore, score) then
			max = item
			maxScore = score
		end
	end
	return max
end

---Computes the maximum element in an array. Returns nil if the array is empty.
---@generic T
---@param array T[]
---@param compare? fun(maxScore: T, score: T): boolean
---@return T
function Array.max(array, compare)
	return Array.maxBy(array, function(x) return x end, compare)
end

---Computes the minimum element in an array according to a scoring function. Returns nil if the array is empty.
---@generic T, V
---@param array T[]
---@param funct fun(item: T): V
---@param compare? fun(score: V, minScore: V): boolean
---@return V?
function Array.minBy(array, funct, compare)
	compare = compare or Array.lexicalCompareIfTable

	local min, minScore
	for _, item in ipairs(array) do
		local score = funct(item)
		if min == nil or compare(score, minScore) then
			min = item
			minScore = score
		end
	end
	return min
end

---Computes the minimum element in an array. Returns nil if the array is empty.
---@generic T
---@param array T[]
---@param compare? fun(score: T, minScore: T): boolean
---@return T
function Array.min(array, compare)
	return Array.minBy(array, function(x) return x end, compare)
end

--[[
Finds the index of the element in an array satisfying a predicate. Returs 0
if no element satisfies the predicate.

Example:

Array.indexOf({3, 5, 4, 6, 7}, function(x) return x % 2 == 0 end)
-- returns 3
]]
---@generic V
---@param array V[]
---@param pred fun(elem: V, ix: integer?): boolean
---@return integer
function Array.indexOf(array, pred)
	for ix, elem in ipairs(array) do
		if pred(elem, ix) then
			return ix
		end
	end
	return 0
end

--[[
Returns distinct/unique elements of an array.

Example:

Array.unique({4, 5, 4, 3})
-- Returns {4, 5, 3}
]]
---@generic V
---@param elements V[]
---@return V[]
function Array.unique(elements)
	local elementCache = {}
	local uniqueElements = {}
	for _, element in ipairs(elements) do
		if elementCache[element] == nil then
			table.insert(uniqueElements, element)
			elementCache[element] = true
		end
	end
	return uniqueElements
end

---@param inputString string?
---@param sep string?
---@return string[]
function Array.parseCommaSeparatedString(inputString, sep)
	if Logic.isEmpty(inputString) then return {} end
	---@cast inputString -nil
	return Array.map(mw.text.split(inputString, sep or ','), String.trim)
end

return Array
