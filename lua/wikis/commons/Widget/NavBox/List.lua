---
-- @Liquipedia
-- page=Module:Widget/NavBox/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Ul = HtmlWidgets.Ul
local Li = HtmlWidgets.Li

---@class NavBoxList: Widget
---@operator call(table): NavBoxList
local NavBoxList = Class.new(Widget)

--text-align:center

---@return Widget
function NavBoxList:render()
	local elements = Array.map(self.props.children, function(child)
		return Li{
			children = child
		}
	end)

	return Div{
		classes = {'hlist'},
		css = Table.merge({padding = '0 0.25em'}, self.props.css),
		children = {
			-- interleaving with new lines is needed for better break points on certain widths
			Ul{children = Array.interleave(elements, '\n')}
		}
	}
end

return NavBoxList
