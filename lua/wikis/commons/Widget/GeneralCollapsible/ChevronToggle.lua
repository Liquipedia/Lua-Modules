---
-- @Liquipedia
-- page=Module:Widget/GeneralCollapsible/ChevronToggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = Html.Span

---@return HtmlNode
local function ChevronToggle()
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

return Component.component(ChevronToggle)
