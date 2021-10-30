---
-- @Liquipedia
-- wiki=commons
-- page=Module:Array/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
Namespace of array functions that aren't as commonly used as ones in
Module:Array
]]
local ArrayExt = {}

--[[
Finds the index of the element in an array satisfying a predicate. Returs 0
if no element satisfies the predicate.

Example:

ArrayExt.findIndex({3, 5, 4, 6, 7}, function(x) return x % 2 == 0 end)
-- returns 3
]]
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

ArrayExt.uniqueElement({4, 4, 4})
-- Returns 4
]]
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

return ArrayExt
