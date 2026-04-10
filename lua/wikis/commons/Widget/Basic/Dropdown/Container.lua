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
local Div = HtmlWidgets.Div

local VALID_VARIANTS = {
	inline = true,
	form = true,
}

---@class DropdownContainerWidgetParameters
---@field button string|Widget|(string|Widget)[]
---@field children Renderable|Renderable[]
---@field variant 'inline'|'form'?
---@field classes string[]?
---@field buttonClasses string[]?
---@field buttonAttributes table?
---@field menuClasses string[]?
---@field menuAttributes table?
---@field buttonSize 'xs'|'sm'|'md'|'lg'?
---@field buttonVariant string?

---@class DropdownContainerWidget: Widget
---@operator call(DropdownContainerWidgetParameters): DropdownContainerWidget
---@field props DropdownContainerWidgetParameters
local DropdownContainer = Class.new(Widget)
DropdownContainer.defaultProps = {
	variant = 'inline',
	buttonSize = 'xs',
	buttonVariant = 'ghost',
}

---@return Widget|nil
function DropdownContainer:render()
	if Logic.isEmpty(self.props.children) then
		return nil
	end

	assert(VALID_VARIANTS[self.props.variant], 'Invalid Dropdown variant "' .. self.props.variant .. '"')

	local toggleButton = Button{
		size = self.props.buttonSize,
		variant = self.props.buttonVariant,
		classes = Array.extend('dropdown-widget__toggle', self.props.buttonClasses),
		attributes = Table.merge(self.props.buttonAttributes or {}, {['data-dropdown-toggle'] = 'true'}),
		children = self.props.button
	}

	return Div{
		classes = Array.extend({'dropdown-widget', 'dropdown-widget--' .. self.props.variant}, self.props.classes),
		children = {
			toggleButton,
			Div{
				classes = Array.extend('dropdown-widget__menu', self.props.menuClasses),
				attributes = self.props.menuAttributes,
				children = self.props.children
			}
		}
	}
end

return DropdownContainer
