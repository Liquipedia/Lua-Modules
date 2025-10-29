---
-- @Liquipedia
-- page=Module:Widget/GeneralCollapsible/Toggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = HtmlWidgets.Span

---@class CollapsibleToggle: Widget
---@operator call(table?): CollapsibleToggle
local CollapsibleToggle = Class.new(Widget)

---@return Widget
function CollapsibleToggle:render()
	local showButton = Button{
		classes = {'general-collapsible-expand-button'},
		children = Span{
			children = {
				Icon{iconName = 'show'},
				' ',
				'Show'
			},
		},
		size = 'xs',
		variant = 'secondary',
	}
	local hideButton = Button{
		classes = {'general-collapsible-collapse-button'},
		children = Span{
			children = {
				Icon{iconName = 'hide'},
				' ',
				'Hide'
			},
		},
		size = 'xs',
		variant = 'secondary',
	}

	return Span{
		classes = {'general-collapsible-default-toggle', unpack(self.props.classes or {})},
		css = self.props.css,
		attributes = self.props.attributes,
		children = {
			showButton,
			hideButton,
		}
	}
end

return CollapsibleToggle
