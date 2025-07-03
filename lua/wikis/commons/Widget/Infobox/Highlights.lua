---
-- @Liquipedia
-- page=Module:Widget/Infobox/Highlights
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class HighlightsWidget: Widget
---@operator call(table):HighlightsWidget
local Highlights = Class.new(Widget)

---@return Widget?
function Highlights:render()
	if Table.isEmpty(self.props.children) then
		return nil
	end
	local listItems = Array.map(self.props.children, function(child)
		return HtmlWidgets.Li{children = {child}}
	end)
	return HtmlWidgets.Div{
		children = HtmlWidgets.Div{
			children = {HtmlWidgets.Ul{children = listItems}},
		}
	}
end

return Highlights
