---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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

	if widget:is_a(Customizable) then
		for _, child in ipairs(widget:tryMake() or {}) do
			if child['is_a'] == nil or child:is_a(Widget) == false then
				return error('Customizable can only contain Widgets as children')
			end

			child:setContext({injector = injector})

			for _, item in ipairs(child:tryMake() or {}) do
				table.insert(convertedWidgets, item)
			end
		end
	else
		return widget:tryMake()
	end

	return convertedWidgets
end

return WidgetFactory
