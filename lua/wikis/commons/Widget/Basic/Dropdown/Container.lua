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
local Div = HtmlWidgets.Div

---@class DropdownContainerWidgetParameters
---@field button string|Widget|(string|Widget)[]
---@field children Renderable|Renderable[]
---@field classes string[]?

---@class DropdownContainerWidget: Widget
---@operator call(DropdownContainerWidgetParameters): DropdownContainerWidget
---@field props DropdownContainerWidgetParameters
local DropdownContainer = Class.new(Widget)

---@return Widget|nil
function DropdownContainer:render()
	if Logic.isEmpty(self.props.children) then
		return nil
	end

	local toggleButton = Button{
		size = 'xs',
		variant = 'ghost',
		classes = {'dropdown-widget__toggle'},
		attributes = {['data-dropdown-toggle'] = 'true'},
		children = self.props.button
	}

	return Div{
		classes = Array.extend('dropdown-widget', self.props.classes),
		children = {
			toggleButton,
			Div{
				classes = {'dropdown-widget__menu'},
				children = self.props.children
			}
		}
	}
end

return DropdownContainer
