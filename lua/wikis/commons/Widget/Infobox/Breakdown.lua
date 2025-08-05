---
-- @Liquipedia
-- page=Module:Widget/Infobox/Breakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class BreakdownWidget: Widget
---@operator call(table):BreakdownWidget
---@field classes string[]
---@field contentClasses table<integer, string[]> --can have gaps in the outer table
local Breakdown = Class.new(Widget)
Breakdown.defaultProps = {
	classes = {},
	contentClasses = {},
}

---@return Widget?
function Breakdown:render()
	if Table.isEmpty(self.props.children) then
		return nil
	end

	local number = #self.props.children
	local mappedChildren = Array.map(self.props.children, function(child, childIndex)
		return HtmlWidgets.Div{
			children = {child},
			classes = WidgetUtil.collect(
				'infobox-cell-' .. number,
				self.props.classes,
				self.props.contentClasses['content' .. childIndex]
			),
		}
	end)
	return HtmlWidgets.Div{
		children = mappedChildren,
	}
end

return Breakdown
