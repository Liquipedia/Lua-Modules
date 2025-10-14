-- @Liquipedia
-- page=Module:Widget/Analytics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class AnalyticsWidget: Widget
---@operator call(table): AnalyticsWidget
local AnalyticsWidget = Class.new(Widget)

---@return Widget
function AnalyticsWidget:render()
	local analyticsName = self.props.analyticsName
	local analyticsKey = self.props.analyticsKey
	local analyticsMapping = self.props.analyticsMapping

	if not analyticsName and analyticsKey and analyticsMapping then
		analyticsName = analyticsMapping[analyticsKey]
	end

	if analyticsName then
		return Div{
			attributes = {['data-analytics-name'] = analyticsName},
			children = self.props.children
		}
	else
		return self.props.children
	end
end

return AnalyticsWidget