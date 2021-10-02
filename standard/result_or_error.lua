---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultOrError
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

--[[
A structurally typed, immutable class that represents either a result or an
error. Used for representing the outcome of a function that can throw.

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
	return ret.error and ret or self
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
local Result = Class.new(ResultOrError, function(self, result)
	self.result = result
end)

function Result:map(f, _)
	return f
		and ResultOrError.try(function() return f(self.result) end)
		or self
end

function Result:get()
	return self.result
end

--[[
Error case.

The stacks argument is the stack traces for the error, so that if an error
handler throws, then the stack trace of the error handler error can be a
continuation of the stack trace of the error that was handled (and so on).
This allows error handlers to rethrow the original error without losing the
stack trace, and is needed to implement :finally().
]]
local Error = Class.new(ResultOrError, function(self, error, stacks)
	self.error = error
	self.stacks = stacks
end)

function Error:map(_, onError)
	return onError
		and ResultOrError.try(function() return onError(self.error) end, self.stacks)
		or ResultOrError.Result()
end

function Error:get()
	error(table.concat(Array.extend(self.error, self.stacks), '\n'))
end

--[[
Invokes a function and places its outcome (result or caught error) in a
ResultOrError. If the result is a ResultOrError, then it is flattened, so that
a nested ResultOrError is avoided.

Additional stack traces can be attached using the lowerStacks parameter. This
can be used when rethrowing an error to include the stack trace of the existing
error. Errors rethrown in ResultOrError:map() or ResultOrError:catch() will
automatically include both stack traces.
]]
function ResultOrError.try(f, lowerStacks)
	local resultOrError
	xpcall(
		function()
			local result = f()
			local isResultOrError = type(result) == 'table'
				and type(result.is_a) == 'function'
				and result:is_a(ResultOrError)
			resultOrError = isResultOrError
				and result
				or Result(result)
		end,
		function(error)
			resultOrError = Error(error, Array.extend(debug.traceback(), lowerStacks))
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
	return Result(results)
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
	return Error(table.concat(errors, '\n'))
end

ResultOrError.Result = Result
ResultOrError.Error = Error

return ResultOrError
