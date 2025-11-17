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
---@field props {children: (string|number|Html|Widget)[], css: string[], supressHtmlList: boolean?}
local NavBoxList = Class.new(Widget)

---@return Widget
function NavBoxList:render()
	local elements = self.props.children

	if not self.props.supressHtmlList then
		elements = Array.map(self.props.children, function(child)
			return Li{
				children = child
			}
		end)
	end

	-- interleaving with new lines is needed for better break points on certain widths
	elements = Array.interleave(elements, '\n')

	if not self.props.supressHtmlList then
		elements = {Ul{children = elements}}
	end

	return Div{
		classes = {'hlist'},
		css = Table.merge({padding = '0 0.25em'}, self.props.css),
		children = elements
	}
end

return NavBoxList
