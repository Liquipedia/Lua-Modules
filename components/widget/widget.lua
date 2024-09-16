---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local Class = require('Module:Class')
local ErrorDisplay = require('Module:Error/Display')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

---@class Widget: BaseClass
---@operator call({children: Widget[]?}?): Widget
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

---@param children string[]
---@return string|nil
function Widget:make(children)
	error('A Widget must override the make() function!')
end

---@return string|nil
function Widget:tryMake(injector)
	local processedChildren = self:tryChildren(injector)
	return Logic.tryOrElseLog(
		function() return self:make(processedChildren) end,
		function(error) return tostring(ErrorDisplay.InlineError(error)) end,
		function(error)
			error.header = 'Error occured in widget: (caught by Widget:tryMake)'
			return error
		end
	)
end

---@param injector WidgetInjector?
---@return string[]
function Widget:tryChildren(injector)
	local children = self.children
	if self.makeChildren then
		children = self:makeChildren(injector) or {}
	end
	return Array.map(children, function(child)
		if type(child) == 'table' and type(child['is_a']) == 'function' and child:is_a(Widget) then
			---@cast child Widget
			return Logic.tryOrElseLog(
				function() return child:tryMake(injector) end,
				function(error) return tostring(ErrorDisplay.InlineError(error)) end,
				function(error)
					error.header = 'Error occured in widget: (caught by Widget:tryChildren)'
					return error
				end
			)
		end
		---@cast child -Widget
		return tostring(child)
	end)
end

return Widget
