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
local WidgetUtil = Lua.import('Module:Widget/Util')
local Span = Html.Span

---@class ChevronToggleProps
---@field expandText Renderable? optional label shown next to the expand chevron
---@field collapseText Renderable? optional label shown next to the collapse chevron
---@field size ('xs'|'sm'|'md'|'lg')? button size, defaults to 'xs'

local defaultProps = {
	size = 'xs',
}

---@param class string
---@param text Renderable?
---@param iconName string
---@param size 'xs'|'sm'|'md'|'lg'
---@return Widget
local function chevronButton(class, text, iconName, size)
	return Button{
		classes = {class},
		children = Span{
			children = WidgetUtil.collect(text, text and ' ' or nil, Icon{iconName = iconName}),
		},
		size = size,
		-- Ghost (borderless, text-friendly) when a label is shown; icon-only otherwise.
		variant = text and 'ghost' or 'icon',
	}
end

---@param props ChevronToggleProps
---@return HtmlNode
local function ChevronToggle(props)
	local expandButton = chevronButton('general-collapsible-expand-button', props.expandText, 'expand', props.size)
	local collapseButton = chevronButton('general-collapsible-collapse-button', props.collapseText, 'collapse', props.size)

	return Span{
		classes = {'general-collapsible-default-toggle'},
		children = {
			expandButton,
			collapseButton,
		}
	}
end

return Component.component(ChevronToggle, defaultProps)
