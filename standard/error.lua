---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error
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
A minimal error class, whose purpose is to allow additional fields to be
attached to an error message string. It has only one method, the __tostring
metamethod, and one required field, error.message.

The class is intended to be open, meaning that its fields are all public and
can be used for any purpose. By convention, the following fields have specific
meanings:

error.message: A short error message describing the error. (Required)

error.stacks: The stack traces of the error. The first stack trace is the one
last thrown. Subsequent stack traces are from when the error was rethrown by an
error handler handling the same error.

error.originalErrors: When an error handler throws (not a rethrow), the original
error that it was handling is tracked here.

error.childErrors: A composite error is one that aggregates many errors into a
summary. Composite errors will place child errors here.

error.innerError: Used when an error instance wraps something that's not a
message string.

error.header: Generic error handlers like Logic.tryOrElseLog will place a
preamble-like text here to give some context to the error.

error.noStack: Disables the stack trace

]]
---@class Error: BaseClass
---@operator call(string|table|nil|any):Error
---@field message string
---@field childErrors? Error[]
---@field header string?
---@field innerError any
---@field originalErrors? Error[]
---@field stacks? string[]
local Error = Class.new(function(self, any)
	-- Normalize the various ways an error can be thrown
	if type(any) == 'string' then
		self.message = any
	elseif type(any) == 'table' then
		local props = any
		for key, value in pairs(props) do
			self[key] = value
		end
	elseif any ~= nil then
		self.message = tostring(any)
		self.innerError = any
	end

	self.message = self.message or 'Unknown error'
end)

---@param error Error
---@return boolean
function Error.isError(error)
	return type(error) == 'table'
		and type(error.is_a) == 'function'
		and error:is_a(Error)
		and type(error.message) == 'string'
end

function Error:__tostring()
	return self.message
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

	local errorSplit = mw.text.split(self.message, ':', true)
	local errorText
	if #errorSplit == 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s.', unpack(errorSplit))
	elseif #errorSplit > 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s', unpack(Array.sub(errorSplit, 1, 4)))
		errorText = errorText .. ':' .. table.concat(Array.sub(errorSplit, 5), ':') .. '.'
	else
		errorText = string.format('Lua error: %s.', self.message)
	end
	return Json.stringify({
			errorShort = errorText,
			stackTrace = stackTrace,
		}, {asArray = true})
end

return Error
