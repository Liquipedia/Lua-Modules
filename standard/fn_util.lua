---
-- @Liquipedia
-- wiki=commons
-- page=Module:FnUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--
-- Utility functions that operate on functions.
--
local FnUtil = {}

-- Creates a memoized copy of a 0 or 1 param function.
function FnUtil.memoize(f)
	local called = {}
	local results = {}
	local nilCalled = false
	local nilResult
	return function(x)
		if x == nil then
			if not nilCalled then
				nilCalled = true
				nilResult = f(x)
			end
			return nilResult
		else
			if not called[x] then
				called[x] = true
				results[x] = f(x)
			end
			return results[x]
		end
	end
end

--[[
Memoized variant of the Y combinator. Useful for caching results of recursive
functions, so that previously computed inputs are not recomputed.

Example:
local fibonacci = FnUtil.memoizeY(function(x, fibonacci)
	if x == 0 then return 0
	elseif x == 1 then return 1
	else return fibonacci(x - 1) + fibonacci(x - 2) end
end)
fibonacci(7) -- returns 13
]]
function FnUtil.memoizeY(f)
	local yf
	yf = FnUtil.memoize(function(x) return f(x, yf) end)
	return yf
end

--[[
Lazily defines a function, by defining the function now but not constructing
the function until it is actually used.

Example:
local parser = FnUtil.lazilyDefineFunction(function() return constructParserFromSpec(spec) end)
parser('')
]]
function FnUtil.lazilyDefineFunction(getf_)
	local getf = FnUtil.memoize(getf_)
	return function(...)
		return getf()(...)
	end
end

-- The identity function
function FnUtil.identity(x) return x end

return FnUtil
