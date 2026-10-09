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

---@param buttonType 'expand'|'collapse'
---@param text Renderable?
---@param iconName string
---@param buttonSize 'xs'|'sm'|'md'|'lg'|nil
---@return VNode
local function labeledButton(buttonType, text, iconName, buttonSize)
	return Button{
		classes = {'general-collapsible-' .. buttonType .. '-button'},
		children = Span{
			children = WidgetUtil.collect(text, text and ' ' or nil, Icon{iconName = iconName}),
		},
		size = buttonSize,
		variant = 'ghost',
	}
end

---@class LabeledChevronToggleProps
---@field expandText Renderable? label shown next to the expand chevron
---@field collapseText Renderable? label shown next to the collapse chevron
---@field buttonSize 'xs'|'sm'|'md'|'lg'|nil

---@param props LabeledChevronToggleProps
---@return HtmlNode
local function LabeledChevronToggle(props)
	return Span{
		classes = {'general-collapsible-default-toggle'},
		children = {
			labeledButton('expand', props.expandText, 'expand', props.buttonSize),
			labeledButton('collapse', props.collapseText, 'collapse', props.buttonSize),
		}
	}
end

return Component.component(LabeledChevronToggle, {buttonSize = 'sm'})
