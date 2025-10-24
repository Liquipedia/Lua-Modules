---
-- @Liquipedia
-- page=Module:Widget/Analytics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class AnalyticsWidget: Widget
---@operator call(table): AnalyticsWidget
local AnalyticsWidget = Class.new(Widget)

---@return Widget
function AnalyticsWidget:render()
    local analyticsName = self.props.analyticsName

    if analyticsName then
        local attributes = {
            ['data-analytics-name'] = analyticsName
        }

        if self.props.analyticsProperties then
            Table.iter.forEachPair(self.props.analyticsProperties, function(key, value)
                attributes['data-analytics-' .. key] = value
            end)
        end

        return Div{
            attributes = attributes,
            children = self.props.children
        }
	end

	return HtmlWidgets.Fragment{children = self.props.children}
end

return AnalyticsWidget

