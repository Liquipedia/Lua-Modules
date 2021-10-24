---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultOrError
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Error = require('Module:Error')
local FeatureFlag = require('Module:FeatureFlag')

--[[
A structurally typed, immutable class that represents either a result or an
error. Used for representing the outcome of a function that can throw.

ResultOrError expects functions that return one value. Additional return values
are ignored.

Usage:

local socketOrError = ResultOrError.try(function()
	return socketlib.open()
end)
local parsedText = socketOrError
	:map(function(socket)
		return socket:readAll()
	end)
	:map(FooParser.parse)
	:finally(function()
		socketOrError:map(function(socket) socket:close() end)
	end)
	:get()
]]
local ResultOrError = Class.new(function(self)
	-- ResultOrError is an abstract class. Don't call this constructor directly.
	--error('Cannot construct abstract class')
end)

-- Applies a function to the result, or handles the error
function ResultOrError:map(f, onError) error('Abstract method') end

-- Returns the result or rethrows the error
function ResultOrError:get() error('Abstract method') end

function ResultOrError:catch(onError)
	return self:map(nil, onError)
end

function ResultOrError:finally(f)
	local ret = self:map(f, f)
	if ret.error then
		return ret
	else
		return self
	end
end

function ResultOrError:isResult()
	return self:is_a(ResultOrError.Result)
end

function ResultOrError:isError()
	return self:is_a(ResultOrError.Error)
end

--[[
Result case
]]
ResultOrError.Result = Class.new(ResultOrError, function(self, result)
	self.result = result
end)

function ResultOrError.Result:map(f, _)
	return f
		and ResultOrError.try(function() return f(self.result) end)
		or self
end

function ResultOrError.Result:get()
	return self.result
end

--[[
Error case. The error is an Error instance.
]]
ResultOrError.Error = Class.new(ResultOrError, function(self, error)
	self.error = error
end)

function ResultOrError.Error:map(_, onError)
	return onError
		and ResultOrError.try(function() return onError(self.error) end, self.error)
		or ResultOrError.Result()
end

function ResultOrError.Error:get()
	error(self.error)
end

--[[
Invokes a function and places its outcome (result or caught error) in a
ResultOrError. If the result is a ResultOrError, then it is flattened, so that
a nested ResultOrError is avoided.

originalError is used when ResultOrError.try is invoking an error handler. It
allows errors thrown in ResultOrError:map() or ResultOrError:catch() to include
stack traces from both the thrown error and the error being handled.
]]
function ResultOrError.try(f, originalError)
	local resultOrError
	xpcall(
		function()
			local result = f()
			local isResultOrError = type(result) == 'table'
				and type(result.is_a) == 'function'
				and result:is_a(ResultOrError)
			resultOrError = isResultOrError
				and result
				or ResultOrError.Result(result)
		end,
		function(any)
			local error = Error.isError(any) and any or Error(any)

			-- Error handler threw a different error than the original error
			if originalError and error ~= originalError then
				if type(error.originalErrors) ~= 'table' then
					error.originalErrors = {}
				end
				table.insert(error.originalErrors, originalError)

			-- Not an error handler, or error handler rethrow
			elseif not error.noStack then
				if type(error.stacks) ~= 'table' then
					error.stacks = {}
				end
				table.insert(error.stacks, 1, debug.traceback())
			end

			resultOrError = ResultOrError.Error(error)
		end
	)
	return resultOrError
end

--[[
If all input ResultOrErrors are results, then returns an ResultOrError of the
array of results. Otherwise returns a ResultOrError of the first error. Note
that this function swaps the types: it converts an array of ResultOrErrors of
values into a ResultOrError of an array of values.
]]
function ResultOrError.all(resultOrErrors)
	local results = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			table.insert(results, resultOrError.result)
		else
			return resultOrError
		end
	end
	return ResultOrError.Result(results)
end

--[[
If any input ResultOrErrors is a result, then returns the first such
ResultOrError. Otherwise, all input ResultOrErrors are errors, and this
aggregates them together and returns a ResultOrError of the aggregate error.
]]
function ResultOrError.any(resultOrErrors)
	local errors = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			return resultOrError
		else
			table.insert(errors, resultOrError.error)
		end
	end
	local error = {
		childErrors = errors,
		message = table.concat(errors, '\n'),
		stacks = {debug.traceback()},
	}
	return ResultOrError.Error(error)
end

--[[
A simple linear congruential generator with 16-bit state and 8-bit output.

State is stored on page variables. Use {{#vardefine:seed|...}} to reset and
seed.
]]
local function lcg8()
	local PageVariableNamespace = require('Module:PageVariableNamespace')
	local globalVars = PageVariableNamespace()
	local pageVars = PageVariableNamespace('ResultOrError')

	local function iter(state)
		return (25385 * state + 1) % 0x10000
	end

	return function()
		local seedVar = globalVars:get('seed')
		local seed
		if seedVar then
			seed = tonumber(seedVar) % 0x10000
			globalVars:delete('seed')
		end

		local state = seed and iter(seed)
			or tonumber(pageVars:get('state'))
			or iter(0)
		state = iter(state)
		pageVars:set('state', state)
		return math.floor(state / 0x100)
	end
end

--[[
Inject random errors into ResultOrError.try, so that each call has a probabilty
of failing.

ResultOrError.try invoked from error handlers are unaffected.
]]
function ResultOrError.setupRandomErrors(failRate)
	local random = lcg8()
	local try = ResultOrError.try
	ResultOrError.try = function(f, originalError)
		return try(
			function()
				if originalError == nil and random() / 0x100 < failRate then
					error('Simulated error (failRate=' .. failRate .. ')')
				end
				return f()
			end,
			originalError
		)
	end
end

if FeatureFlag.get('random_errors') then
	ResultOrError.setupRandomErrors(0.1)
end

return ResultOrError
