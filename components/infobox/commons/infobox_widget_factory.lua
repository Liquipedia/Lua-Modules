---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Customizable = require('Module:Infobox/Widget/Customizable')
local Widget = require('Module:Infobox/Widget')

local WidgetFactory = Class.new()

function WidgetFactory.work(widget, injector)
	local convertedWidgets = {}

	if widget:is_a(Customizable) then
		for _, child in pairs(widget:make() or {}) do
			if child['is_a'] == nil or child:is_a(Widget) == false then
				return error('Customizable can only contain Widgets as children')
			end
			for _, item in pairs(child:make() or {}) do
				table.insert(convertedWidgets, item)
			end
		end
	else
		return widget:make()
	end

	return convertedWidgets
end

return WidgetFactory
