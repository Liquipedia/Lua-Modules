
--[[
Finds the index of the element in an array satisfying a predicate. Returs 0
if no element satisfies the predicate.

Example:

Array.findIndex({3, 5, 4, 6, 7}, function(x) return x % 2 == 0 end)
-- returns 3
]]
---@generic V
---@param array V[]
---@param pred fun(elem: V, ix: integer?): boolean
---@return integer
function ArrayExt.findIndex(array, pred)
	for ix, elem in ipairs(array) do
		if pred(elem, ix) then
			return ix
		end
	end
	return 0
end

--[[
Returns the unique element in an array. Returns nil if there is more than one
distinct element, or if the array is empty.

Example:

Array.uniqueElement({4, 4, 4})
-- Returns 4
]]
---@generic V
---@param elems V[]
---@return V?
function ArrayExt.uniqueElement(elems)
	local uniqueElem
	for i, elem in ipairs(elems) do
		if i ~= 1 and elem ~= uniqueElem then
			return nil
		end
		uniqueElem = elem
	end
	return uniqueElem
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
function ArrayExt.groupAdjacentBy(array, f, equals)
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

--[[
Returns distinct elements of an array.

Example:

Array.distinct({4, 5, 4, 3})
-- Returns {4, 5, 3}
]]
---@generic V
---@param elements V[]
---@return V[]
function ArrayExt.distinct(elements)
	local elementCache = {}
	local distinctElements = {}
	for _, element in ipairs(elements) do
		if elementCache[element] == nil then
			table.insert(distinctElements, element)
			elementCache[element] = true
		end
	end
	return distinctElements
end

return Array
