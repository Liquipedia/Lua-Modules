---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown/Container
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
local WidgetUtil = Lua.import('Module:Widget/Util')
local Div = Html.Div
local Span = Html.Span

local VARIANT_CONFIG = {
	inline = {
		size = 'xs',
		variant = 'ghost',
	},
	form = {
		size = 'md',
		variant = 'secondary',
	},
}

---@class DropdownContainerWidgetParameters
---@field children Renderable|Renderable[]
---@field variant 'form'|'inline'?
---@field classes string[]?
---@field prefix Renderable|Renderable[]?
---@field label Renderable|Renderable[]?

---@class DropdownContainerWidget
local DropdownContainer = {}
DropdownContainer.defaultProps = {
	variant = 'form',
}

---@param props DropdownContainerWidgetParameters
---@return HtmlNode?
function DropdownContainer.render(props)
	if Logic.isEmpty(props.children) then
		return nil
	end

	local variantConfig = assert(VARIANT_CONFIG[props.variant],
		'Invalid Dropdown variant "' .. props.variant .. '"')

	local toggleChildren = WidgetUtil.collect(
		Logic.isNotEmpty(props.prefix) and Span{
			classes = {'dropdown-widget__prefix'},
			children = props.prefix,
		} or nil,
		Span{
			classes = {'dropdown-widget__label'},
			children = props.label,
		},
		Span{
			classes = {'dropdown-widget__indicator'},
			children = {Icon{iconName = 'expand', size = 'xs'}},
		}
	)

	local toggleButton = Button{
		size = variantConfig.size,
		variant = variantConfig.variant,
		classes = {'dropdown-widget__toggle'},
		attributes = {
			['data-dropdown-toggle'] = 'true',
			['aria-expanded'] = 'false',
			['aria-haspopup'] = 'menu',
		},
		children = toggleChildren
	}

	return Div{
		classes = Array.extend({'dropdown-widget', 'dropdown-widget--' .. props.variant}, props.classes),
		children = {
			toggleButton,
			Div{
				classes = {'dropdown-widget__menu'},
				attributes = {['aria-hidden'] = 'true'},
				children = props.children
			}
		}
	}
end

return Component.component(DropdownContainer.render, DropdownContainer.defaultProps)
