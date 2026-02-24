---
-- @Liquipedia
-- page=Module:Widget/Analytics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class AnalyticsWidgetParameters
---@field analyticsName string?
---@field analyticsProperties table<string, string>?
---@field classes string[]?
---@field children Renderable|Renderable[]?
---@field css table<string, string|integer?>?

---@class AnalyticsWidget: Widget
---@operator call(AnalyticsWidgetParameters): AnalyticsWidget
---@field props AnalyticsWidgetParameters
local AnalyticsWidget = Class.new(Widget)

---@return Renderable|Renderable[]?
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
			classes = self.props.classes,
			css = self.props.css,
			children = self.props.children
		}
	end

	if Logic.isEmpty(self.props.classes) then
		return self.props.children
	end

	return Div{
		classes = self.props.classes,
		children = self.props.children
	}
end

return AnalyticsWidget

