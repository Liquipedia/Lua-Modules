---
-- @Liquipedia
-- page=Module:Widget/Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local RatingsList = Lua.import('Module:Widget/Ratings/List')

---@class Ratings: Widget
---@operator call(table): Ratings
local Ratings = Class.new(Widget)
Ratings.defaultProps = {
	teamLimit = 20,
	storageType = 'lpdb',
	showGraph = true,
	isSmallerVersion = false,
}

---@return Widget
function Ratings:render()
	return HtmlWidgets.Div {
		attributes = {
			class = 'ranking-table__wrapper',
		},
		children = WidgetUtil.collect(
			RatingsList {
				teamLimit = self.props.teamLimit,
				storageType = self.props.storageType,
				showGraph = self.props.showGraph,
				isSmallerVersion = self.props.isSmallerVersion,
			}
		),
	}
end

return Ratings
