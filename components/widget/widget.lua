---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local ErrorDisplay = require('Module:Error/Display')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

---@class WidgetParameters
---@field children (Widget|Html|string|number)[]?

---@class Widget: BaseClass
---@operator call(WidgetParameters): Widget
---@field children (Widget|Html|string|number)[]
---@field makeChildren? fun(self:Widget, injector: WidgetInjector?): Widget[]?
local Widget = Class.new(function(self, input)
	self.children = input and input.children or {}
end)

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	return assert(String.nilIfEmpty(value), 'Tried to set a nil value to a mandatory property')
end

---@param children string[]? #Backwards compatibility
---@return string|nil
function Widget:make(children)
	error('A Widget must override the make() function!')
end

---@return string|nil
function Widget:tryMake()
	return Logic.tryOrElseLog(
		function() return self:make(self.children) end,
		function(error) return tostring(ErrorDisplay.InlineError(error)) end,
		function(error)
			error.header = 'Error occured in widget: (caught by Widget:tryMake)'
			return error
		end
	)
end

---@return string
function Widget:__tostring()
	return self:tryMake() or ''
end

return Widget
