---
-- @Liquipedia
-- page=Module:ResultOrError
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Error = require('Module:Error')

--[[
A structurally typed, immutable class that represents either a result or an
error. Used for representing the outcome of a function that can throw.

ResultOrError expects functions that return one value. Additional return values
are ignored.

Usage:
```
local socketOrError = ReltOrError.try(function()
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
```
]]
---@class ResultOrError: BaseClass
local ResultOrError = Class.new(function(self)
	-- ResultOrError is an abstract class. Don't call this constructor directly.
	--error('Cannot construct abstract class')
end)

-- Applies a function to the result, or handles the error
---@param f? fun(any: any): any
---@param onError? fun(error: Error?): any
---@return ResultOrError
function ResultOrError:map(f, onError) error('Abstract method') end

-- Returns the result or rethrows the error
---@return any
function ResultOrError:get() error('Abstract method') end

---@param onError fun(error: Error?): any
---@return ResultOrError
function ResultOrError:catch(onError)
	return self:map(nil, onError)
end

---@param f fun(error: Error?): any
---@return ResultOrError
function ResultOrError:finally(f)
	local ret = self:map(f, f)
	if ret:isError() then
		return ret
	end
	return self
end

---@return boolean
function ResultOrError:isResult()
	return Class.instanceOf(self, ResultOrError.Result)
end

---@return boolean
function ResultOrError:isError()
	return Class.instanceOf(self, ResultOrError.Error)
end

--[[
Result case
]]
---@class RoEResult: ResultOrError
---@field result any
ResultOrError.Result = Class.new(ResultOrError, function(self, result)
	self.result = result
end)

---@param f? fun(any: any): any
---@param _ any
---@return RoEResult|RoEError
function ResultOrError.Result:map(f, _)
	return f
		and ResultOrError.try(function() return f(self.result) end)
		or self
end

---@return any
function ResultOrError.Result:get()
	return self.result
end

---Error case. The error field is an Error instance.
---@class RoEError: ResultOrError
---@field error Error
ResultOrError.Error = Class.new(ResultOrError, function(self, error)
	self.error = error
end)

---@param _ any
---@param onError? fun(error: Error?): any
---@return RoEResult|RoEError
function ResultOrError.Error:map(_, onError)
	return onError
		and ResultOrError.try(function() return onError(self.error) end, self.error)
		or ResultOrError.Result()
end

---Errors with a JSON string for use by `liquipedia.customLuaErrors` JS module.
---@return any
function ResultOrError.Error:get()
	error(tostring(self.error))
end

--[[
Invokes a function and places its outcome (result or caught error) in a
ResultOrError. If the result is a ResultOrError, then it is flattened, so that
a nested ResultOrError is avoided.

originalError is used when ResultOrError.try is invoking an error handler. It
allows errors thrown in ResultOrError:map() or ResultOrError:catch() to include
stack traces from both the thrown error and the error being handled.
]]
---@param f fun(): any
---@param originalError table?
---@return RoEResult|RoEError
function ResultOrError.try(f, originalError)
	local resultOrError
	xpcall(
		function()
			local result = f()
			local isResultOrError = Class.instanceOf(result, ResultOrError)
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
---@param resultOrErrors ResultOrError[]
---@return RoEResult|RoEError
function ResultOrError.all(resultOrErrors)
	local results = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			---@cast resultOrError RoEResult
			table.insert(results, resultOrError.result)
		else
			---@cast resultOrError RoEError
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
---@param resultOrErrors ResultOrError[]
---@return RoEResult|RoEError
function ResultOrError.any(resultOrErrors)
	local errors = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			---@cast resultOrError RoEResult
			return resultOrError
		else
			---@cast resultOrError RoEError
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

return ResultOrError
