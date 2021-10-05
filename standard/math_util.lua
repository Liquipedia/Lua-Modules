---
-- @Liquipedia
-- wiki=commons
-- page=Module:MathUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MathUtil = {}

--[[
Returns the base 2 log of the input number, rounded down.

Example:
MathUtil.ilog2(8) -- Returns 3
MathUtil.ilog2(24) -- Returns 4
]]
function MathUtil.ilog2(x)
	return math.floor(math.log(x) / math.log(2))
end

--[[
Returns the sum of an array.

Example:
MathUtil.sum({3, 5, 4})
-- Returns 12
]]
function MathUtil.sum(xs)
	local sum = 0
	for _, x in ipairs(xs) do
		sum = sum + x
	end
	return sum
end

--[[
Computes the partial sums of an array. The result is an array one longer than
the input.

Example:
MathUtil.partialSums({3, 5, 4})
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
