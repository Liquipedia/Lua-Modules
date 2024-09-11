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
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

---@class Widget: BaseClass
---@operator call({children: Widget[]?}?): Widget
---@field children (Widget|Html|string|number)[]
---@field makeChildren? fun(self:self, injector: WidgetInjector?): string[]
local Widget = Class.new(function(self, input)
	self.children = input and input.children or {}
end)

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	return assert(String.nilIfEmpty(value), 'Tried to set a nil value to a mandatory property')
end

---@param injector WidgetInjector?
---@param children string[]
---@return Widget[]|Html[]|nil
function Widget:make(injector, children)
	error('A Widget must override the make() function!')
end

---@param injector WidgetInjector?
---@return Widget[]|Html[]|nil
function Widget:tryMake(injector)
	local processedChildren = self:tryChildren(injector)
	return Logic.tryOrElseLog(
		function() return self:make(injector, processedChildren) end,
		function(error) return {ErrorDisplay.InlineError(error)} end,
		function(error)
			error.header = 'Error occured in widget: (caught by Widget:tryMake)'
			return error
		end
	)
end

---@param injector WidgetInjector?
---@return string[]
function Widget:tryChildren(injector)
	-- Here due to circular dependency
	local WidgetFactory = Lua.import('Module:Widget/Factory')
	return Array.flatMap(self.children, function(child)
		if type(child) == 'table' and type(child['is_a']) == 'function' and child:is_a(Widget) then
			---@cast child Widget
			return Logic.tryOrElseLog(
				function() return WidgetFactory.work(child, injector) end,
				function(error) return {ErrorDisplay.InlineError(error)} end,
				function(error)
					error.header = 'Error occured in widget: (caught by Widget:tryChildren)'
					return error
				end
			)
		end
		return {tostring(child)}
	end)
end

return Widget
