---
-- @Liquipedia
-- page=Module:Error
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

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
	return Class.instanceOf(error, Error) and type(error.message) == 'string'
end

function Error:__tostring()
	return self.message
end

return Error
