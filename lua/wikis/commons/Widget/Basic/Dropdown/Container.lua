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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

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

	local variantConfig = assert(VARIANT_CONFIG[self.props.variant], 'Invalid Dropdown variant "' .. self.props.variant .. '"')

	local toggleChildren = WidgetUtil.collect(
		Logic.isNotEmpty(self.props.prefix) and Span{
			classes = {'dropdown-widget__prefix'},
			children = self.props.prefix,
		} or nil,
		Span{
			classes = {'dropdown-widget__label'},
			children = self.props.label,
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
		classes = Array.extend({'dropdown-widget', 'dropdown-widget--' .. self.props.variant}, self.props.classes),
		children = {
			toggleButton,
			Div{
				classes = {'dropdown-widget__menu'},
				attributes = {['aria-hidden'] = 'true'},
				children = self.props.children
			}
		}
	}
end

return DropdownContainer
