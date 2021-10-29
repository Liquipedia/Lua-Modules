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

return ArrayExt
