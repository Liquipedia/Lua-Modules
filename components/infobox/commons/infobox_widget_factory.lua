---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Customizable = require('Module:Infobox/Widget/Customizable')
local String = require('Module:StringUtils')
local Widget = require('Module:Infobox/Widget')

local WidgetFactory = Class.new()

local _ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'

function WidgetFactory.work(widget, injector)
	local convertedWidgets = {}

	if widget == nil then
		return {}
	end

	if widget:is_a(Customizable) then
		for _, child in ipairs(WidgetFactory._makeWidget(widget) or {}) do
			if child['is_a'] == nil or child:is_a(Widget) == false then
				return error('Customizable can only contain Widgets as children')
			end

			child:setContext({injector = injector})

			for _, item in ipairs(WidgetFactory._makeWidget(child) or {}) do
				table.insert(convertedWidgets, item)
			end
		end
	else
		return WidgetFactory._makeWidget(widget)
	end

	return convertedWidgets
end

function WidgetFactory._makeWidget(widget)
	local result, output = pcall(widget.make, widget) -- Equivalent of widget:make()
	if not result then
		output = {String.interpolate(_ERROR_TEXT, {errorMessage = output})}
	end
	return output
end

return WidgetFactory
