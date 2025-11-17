---
-- @Liquipedia
-- page=Module:FnUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--
-- Utility functions that operate on functions.
--
local FnUtil = {}

---@alias memoizableFunction fun(input: any): any

---Creates a memoized copy of a 0 or 1 param function.
---@generic T:memoizableFunction
---@param func T
---@return T
function FnUtil.memoize(func)
	local called = {}
	local results = {}
	local nilCalled = false
	local nilResult
	return function(x)
		if x == nil then
			if not nilCalled then
				nilCalled = true
				nilResult = func(x)
			end
			return nilResult
		else
			if not called[x] then
				called[x] = true
				results[x] = func(x)
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
---@generic T
---@param func fun(input: T, self: fun(input: T)):T
---@return fun(input: T): T
function FnUtil.memoizeY(func)
	local yf
	yf = FnUtil.memoize(function(x) return func(x, yf) end)
	return yf
end

--[[
Lazily defines a function, by defining the function now but not constructing
the function until it is actually used.

Example:
local parser = FnUtil.lazilyDefineFunction(function() return constructParserFromSpec(spec) end)
parser('')
]]
---@generic V:fun(...):any
---@param getf_ fun():V
---@return V
function FnUtil.lazilyDefineFunction(getf_)
	local getf = FnUtil.memoize(getf_)
	return function(...)
		return getf()(...)
	end
end

--- The identity function
---@generic T
---@param x T
---@return T
function FnUtil.identity(x) return x end

---Currying is a way to re-write a function with multiple arguments in such a way as it can be
---called as a chain of functions each with a single argument
---@generic T, V, R
---@param func fun(x: T, ...: V):R
---@param x T
---@return fun(...:V):R
function FnUtil.curry(func, x)
	return function(...)
		return func(x, ...)
	end
end

return FnUtil
