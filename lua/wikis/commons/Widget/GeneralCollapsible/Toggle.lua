---
-- @Liquipedia
-- page=Module:Widget/GeneralCollapsible/Toggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = Html.Span

---@class CollapsibleToggleProps: HtmlNodeProps
---@field showButtonChildren? Renderable|Renderable[]
---@field hideButtonChildren? Renderable|Renderable[]

---@param props CollapsibleToggleProps
---@return HtmlNode
local function CollapsibleToggle(props)
	local showButton = Button{
		classes = {'general-collapsible-expand-button'},
		children = Span{
			children = Logic.emptyOr(props.showButtonChildren, {
				Icon{iconName = 'show'},
				' ',
				'Show'
			})
		},
		size = 'xs',
		variant = 'secondary',
	}
	local hideButton = Button{
		classes = {'general-collapsible-collapse-button'},
		children = Span{
			children = Logic.emptyOr(props.hideButtonChildren, {
				Icon{iconName = 'hide'},
				' ',
				'Hide'
			})
		},
		size = 'xs',
		variant = 'secondary',
	}

	return Span{
		classes = Array.extend(
			'general-collapsible-default-toggle',
			props.classes
		),
		css = props.css,
		attributes = props.attributes,
		children = {
			showButton,
			hideButton,
		}
	}
end

return Component.component(CollapsibleToggle)
