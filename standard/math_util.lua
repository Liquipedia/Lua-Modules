---
-- @Liquipedia
-- wiki=commons
-- page=Module:MathUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MathUtil = {}

--[[
Computes the partial sums of an array. The result is an array one longer than
the input.

Example:
math.partialSums({3, 5, 4})
-- Returns {0, 3, 8, 12}
]]
function MathUtil.partialSums(set)
	local sum = 0
	local sums = {0}
	for _, num in ipairs(set) do
		sum = sum + num
		table.insert(sums, sum)
	end
	return sums
end

return MathUtil
