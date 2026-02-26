---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ChevronToggle
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

---@class ChevronToggle: Widget
---@operator call(table?): ChevronToggle
local ChevronToggle = Class.new(Widget)

---@return Widget
function ChevronToggle:render()
	local expandButton = Button{
		classes = {'general-collapsible-expand-button'},
		children = Span{
			children = {
				Icon{iconName = 'expand'},
			},
		},
		size = 'xs',
		variant = 'icon',
	}
	local collapseButton = Button{
		classes = {'general-collapsible-collapse-button'},
		children = Span{
			children = {
				Icon{iconName = 'collapse'},
			},
		},
		size = 'xs',
		variant = 'icon',
	}

	return Span{
		classes = {'general-collapsible-default-toggle'},
		children = {
			expandButton,
			collapseButton,
		}
	}
end

return ChevronToggle
