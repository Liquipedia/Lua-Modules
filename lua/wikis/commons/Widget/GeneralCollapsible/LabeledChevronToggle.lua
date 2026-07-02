---
-- @Liquipedia
-- page=Module:Widget/GeneralCollapsible/LabeledChevronToggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Span = Html.Span

---@param class string
---@param text Renderable?
---@param iconName string
---@return Widget
local function labeledButton(class, text, iconName)
	return Button{
		classes = {class},
		children = Span{
			children = WidgetUtil.collect(text, text and ' ' or nil, Icon{iconName = iconName}),
		},
		size = 'sm',
		variant = 'ghost',
	}
end

---@class LabeledChevronToggleProps
---@field expandText Renderable? label shown next to the expand chevron
---@field collapseText Renderable? label shown next to the collapse chevron

---@param props LabeledChevronToggleProps
---@return HtmlNode
local function LabeledChevronToggle(props)
	return Span{
		classes = {'general-collapsible-default-toggle'},
		children = {
			labeledButton('general-collapsible-expand-button', props.expandText, 'expand'),
			labeledButton('general-collapsible-collapse-button', props.collapseText, 'collapse'),
		}
	}
end

return Component.component(LabeledChevronToggle)
