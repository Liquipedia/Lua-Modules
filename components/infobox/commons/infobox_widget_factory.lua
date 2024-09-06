---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetFactory
local WidgetFactory = Class.new()

---@param widget Widget
---@param injector WidgetInjector?
---@return Html[]
function WidgetFactory.work(widget, injector)
	local convertedWidgets = {} ---@type Html[]

	if widget == nil then
		return {}
	end

	for _, child in ipairs(widget:tryMake(injector) or {}) do
		if type(child) == 'table' and type(child['is_a']) == 'function' and child:is_a(Widget) then
			---@cast child Widget
			Array.extendWith(convertedWidgets, WidgetFactory.work(child, injector))
		else
			---@cast child Html
			table.insert(convertedWidgets, child)
		end
	end

	return convertedWidgets
end

return WidgetFactory
