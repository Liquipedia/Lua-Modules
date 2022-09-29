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

local Customizable = Lua.import('Module:Infobox/Widget/Customizable', {requireDevIfEnabled = true})
local Widget = Lua.import('Module:Infobox/Widget', {requireDevIfEnabled = true})

local WidgetFactory = Class.new()

function WidgetFactory.work(widget, injector)
	local convertedWidgets = {}

	if widget == nil then
		return {}
	end

	for _, child in ipairs(widget:tryMake() or {}) do
		if type(child) == 'table' and child['is_a'] and child:is_a(Widget) then
			child:setContext{injector = injector}
			Array.extendWith(convertedWidgets, WidgetFactory.work(child, injector))
		else
			table.insert(convertedWidgets, child)
		end
	end

	return convertedWidgets
end

return WidgetFactory
