---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings/PlacementChange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class PlacementChangeWidget: Widget
---@operator call(table): PlacementChangeWidget

local PlacementChangeWidget = Class.new(Widget)
PlacementChangeWidget.defaultProps = {
	change = 0,
}

---@return Widget?
function PlacementChangeWidget:render()
	local change = self.props.change
	if change == 0 then
		return HtmlWidgets.Span{children = '-'}
	end
	local positive = change > 0
	return HtmlWidgets.Span{
		classes = {'group-table-rank-change-' .. (positive and 'up' or 'down')},
		children = {
			positive and '▲' or '▼',
			math.abs(change),
		},
	}
end

return PlacementChangeWidget
