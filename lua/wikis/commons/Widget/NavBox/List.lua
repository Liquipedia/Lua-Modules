---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/NavBox/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Ul = HtmlWidgets.Ul
local Li = HtmlWidgets.Li

---@class NavBoxList: Widget
---@operator call(table): NavBoxList
local NavBoxList = Class.new(Widget)

---@return Widget
function NavBoxList:render()
	local elements = Array.mapIndexes(function(index)
		if not self.props[index] then return end
		return Li{
			children = {self.props[index]}
		}
	end)


	return Div{
		classes = {'hlist'},
		css = {padding = '0 0.25em'},
		children = {
			-- interleaving with new lines is needed for better break points on certain widths
			Ul{children = Array.interleave(elements, '\n')}
		}
	}
end

return NavBoxList
