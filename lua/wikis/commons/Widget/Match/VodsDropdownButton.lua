---
-- @Liquipedia
-- page=Module:Widget/Match/VodsDropdownButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local VodLink = Lua.import('Module:VodLink')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = HtmlWidgets.Span

---@class VodsDropdownButton: Widget
---@operator call(table): VodsDropdownButton
local VodsDropdownButton = Class.new(Widget)

---@return Widget?
function VodsDropdownButton:render()
	local vodCount = self.props.count
	if not vodCount then
		return
	end

	local showButton = Button{
		classes = {'general-collapsible-expand-button'},
		children = Span{
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				' ',
				'(' .. vodCount .. ')',
				' ',
				Icon{iconName = 'expand'},
			},
		},
		size = 'sm',
		variant = 'secondary',
	}
	local hideButton = Button{
		classes = {'general-collapsible-collapse-button', 'btn--active'},
		children = Span{
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				' ',
				'(' .. vodCount .. ')',
				' ',
				Icon{iconName = 'collapse'},
			},
		},
		size = 'sm',
		variant = 'secondary',
	}

	return Span{
		classes = {'general-collapsible-default-toggle'},
		css = self.props.css,
		attributes = self.props.attributes,
		children = {
			showButton,
			hideButton,
		}
	}
end

return VodsDropdownButton
