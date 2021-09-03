---
 -- @Liquipedia
 -- wiki=commons
 -- page=Module:Infobox/Widget/Factory
 --
 -- Please see https://github.com/Liquipedia/Lua-Modules to contribute
 --

local Class = require('Module:Class')
local Builder = require('Module:Infobox/Widget/Builder')
local Customizable = require('Module:Infobox/Widget/Customizable')
local Widget = require('Module:Infobox/Widget')

local WidgetFactory = Class.new()

function WidgetFactory.work(widget, injector)
	local convertedWidgets = {}

	if widget:is_a(Builder) then
		local children = widget:make()

		for _, child in pairs(children or {}) do
			local childOutput = WidgetFactory.work(child, injector)
			-- Our child might contain a list of children, so we need to iterate
			for _, item in pairs(childOutput) do
				table.insert(convertedWidgets, item)
			end
		end
	elseif widget:is_a(Customizable) then
		widget:setWidgetInjector(injector)
		for _, child in pairs(widget:make() or {}) do
			if child['is_a'] == nil or child:is_a(Widget) == false then
				return error('Customizable can only contain Widgets as children')
			end
			if child:is_a(Builder) then
				local subChildren = child:make()

				for _, subChild in pairs(subChildren or {}) do
					local childOutput = WidgetFactory.work(subChild, injector)
					-- Our child might contain a list of children, so we need to iterate
					for _, item in pairs(childOutput) do
						table.insert(convertedWidgets, item)
					end
				end
			else
				for _, item in pairs(child:make() or {}) do
					table.insert(convertedWidgets, item)
				end
			end
		end
	else
		return widget:make()
	end

	return convertedWidgets
end

return WidgetFactory
