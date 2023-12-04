---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultOrError
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local FILTERED_ERROR_STACK_ITEMS = {
	'^Module:ResultOrError:%d+: in function <Module:ResultOrError:%d+>$',
	'^%[C%]: in function \'xpcall\'$',
	'^Module:ResultOrError:%d+: in function \'try\'$',
}

--[[
A structurally typed, immutable class that represents either a result or an
error. Used for representing the outcome of a function that can throw.

Usage:
```
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
```
]]
---@class ResultOrError: BaseClass
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
	---@cast ret -nil
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
---@class Result: ResultOrError
---@field result any
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
---@class Error: ResultOrError
---@field error string?
---@field stacks string[]?
local Error = Class.new(ResultOrError, function(self, error, stacks)
	self.error = error
	self.stacks = stacks
end)

function Error:map(_, onError)
	return onError
		and ResultOrError.try(function() return onError(self.error) end, self.stacks)
		or ResultOrError.Result()
end

---Builds a JSON string for use by `liquipedia.customLuaErrors` JS module with `error()`.
---@return string
function Error:getErrorJson()
	local stackTrace = {}

	local processStackFrame = function(frame, frameIndex)
		if frameIndex == 1 and frame == '[C]: ?' then
			return
		end

		local stackEntry = {content = frame}
		local frameSplit = mw.text.split(frame, ':', true)
		if (frameSplit[1] == '[C]' or frameSplit[1] == '(tail call)') then
			stackEntry.prefix = frameSplit[1]
			stackEntry.content = mw.text.trim(table.concat(frameSplit, ':', 2))
		elseif frameSplit[1]:sub(1, 3) == 'mw.' then
			stackEntry.prefix = table.concat(frameSplit, ':', 1, 2)
			stackEntry.content =  table.concat(frameSplit, ':', 3)
		elseif frameSplit[1] == 'Module' then
			local wiki = not Page.exists(table.concat(frameSplit, ':', 1, 2)) and 'commons'
				or mw.text.split(mw.title.getCurrentTitle():canonicalUrl(), '/', true)[4] or 'commons'
			stackEntry.link = {wiki = wiki, title = table.concat(frameSplit, ':', 1, 2), ln = frameSplit[3]}
			stackEntry.prefix = table.concat(frameSplit, ':', 1, 3)
			stackEntry.content = table.concat(frameSplit, ':', 4)
		end

		table.insert(stackTrace, stackEntry)
	end

	Array.forEach(self.stacks, function(stack)
		local stackFrames = mw.text.split(stack, '\n')
		stackFrames = Array.filter(
			Array.map(
				Array.sub(stackFrames, 2, #stackFrames),
				function(frame) return String.trim(frame) end
			),
			function(frame) return not Table.any(FILTERED_ERROR_STACK_ITEMS, function(_, filter)
				return string.find(frame, filter) ~= nil
			end) end
		)
		Array.forEach(stackFrames, processStackFrame)
	end)

	local errorSplit = mw.text.split(self.error, ':', true)
	local errorText
	if #errorSplit == 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s.', unpack(errorSplit))
	elseif #errorSplit > 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s', unpack(Array.sub(errorSplit, 1, 4)))
		errorText = errorText .. ':' .. table.concat(Array.sub(errorSplit, 5), ':') .. '.'
	else
		errorText = string.format('Lua error: %s.', self.error)
	end
	return Json.stringify({
			errorShort = errorText,
			stackTrace = stackTrace,
		}, {asArray = true})
end

---Errors with a JSON string for use by `liquipedia.customLuaErrors` JS module.
function Error:get()
	error(self:getErrorJson(), 0)
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
---@param f function
---@param lowerStacks table?
---@return Result|Error
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
---@param resultOrErrors ResultOrError[]
---@return Result|Error
function ResultOrError.all(resultOrErrors)
	local results = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			---@cast resultOrError Result
			table.insert(results, resultOrError.result)
		else
			---@cast resultOrError Error
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
---@param resultOrErrors ResultOrError[]
---@return Result|Error
function ResultOrError.any(resultOrErrors)
	local errors = {}
	for _, resultOrError in ipairs(resultOrErrors) do
		if resultOrError:isResult() then
			---@cast resultOrError Result
			return resultOrError
		else
			---@cast resultOrError Error
			table.insert(errors, resultOrError.error)
		end
	end
	return Error(table.concat(errors, '\n'))
end

ResultOrError.Result = Result
ResultOrError.Error = Error

return ResultOrError
