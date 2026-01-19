---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local Div = HtmlWidgets.Div

---@class DropdownWidgetParameters
---@field button any -- The content of the toggle button
---@field content Widget|string|table -- The dropdown content
---@field classes table? -- Custom classes for the wrapper

---@class DropdownWidget: Widget
---@operator call(DropdownWidgetParameters): DropdownWidget
local Dropdown = Class.new(Widget)

---@return Widget
function Dropdown:render()
	local toggleButton = Button{
		variant = 'ghost',
		classes = {'dropdown-widget__toggle'},
		attributes = {['data-dropdown-toggle'] = 'true'},
		children = self.props.button
	}

	return Div{
		classes = Array.extend({'dropdown-widget'}, self.props.classes or {}),
		children = {
			toggleButton,
			Div{
				classes = {'dropdown-widget__menu'},
				children = self.props.content
			}
		}
	}
end

return Dropdown
