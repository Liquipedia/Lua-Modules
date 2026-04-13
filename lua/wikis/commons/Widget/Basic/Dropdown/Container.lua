---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

local VALID_VARIANTS = {
	form = true,
	inline = true,
}

local VARIANT_CONFIG = {
	inline = {
		buttonSize = 'xs',
		buttonVariant = 'ghost',
	},
	form = {
		buttonSize = 'md',
		buttonVariant = 'secondary',
	},
}

---@class DropdownContainerWidgetParameters
---@field children Renderable|Renderable[]
---@field variant 'form'|'inline'?
---@field classes string[]?
---@field prefix Renderable|Renderable[]?
---@field label Renderable|Renderable[]?

---@class DropdownContainerWidget: Widget
---@operator call(DropdownContainerWidgetParameters): DropdownContainerWidget
---@field props DropdownContainerWidgetParameters
local DropdownContainer = Class.new(Widget)
DropdownContainer.defaultProps = {
	variant = 'form',
}

---@return Widget|nil
function DropdownContainer:render()
	if Logic.isEmpty(self.props.children) then
		return nil
	end

	assert(VALID_VARIANTS[self.props.variant], 'Invalid Dropdown variant "' .. self.props.variant .. '"')
	local variantConfig = VARIANT_CONFIG[self.props.variant]

	local buttonAttributes = {
		['aria-expanded'] = 'false',
		['aria-haspopup'] = 'menu',
	}
	local menuAttributes = {['aria-hidden'] = 'true'}

	local toggleChildren = {
		Logic.isEmpty(self.props.prefix) and nil or Span{
			classes = {'dropdown-widget__prefix'},
			children = self.props.prefix,
		},
		Span{
			classes = {'dropdown-widget__label'},
			children = self.props.label,
		},
		Span{
			classes = {'dropdown-widget__indicator'},
			children = {Icon{iconName = 'expand', size = 'xs'}},
		},
	}

	local toggleButton = Button{
		size = variantConfig.buttonSize,
		variant = variantConfig.buttonVariant,
		classes = {'dropdown-widget__toggle'},
		attributes = Table.merge(buttonAttributes, {['data-dropdown-toggle'] = 'true'}),
		children = toggleChildren
	}

	return Div{
		classes = Array.extend({'dropdown-widget', 'dropdown-widget--' .. self.props.variant}, self.props.classes),
		children = {
			toggleButton,
			Div{
				classes = {'dropdown-widget__menu'},
				attributes = menuAttributes,
				children = self.props.children
			}
		}
	}
end

return DropdownContainer
