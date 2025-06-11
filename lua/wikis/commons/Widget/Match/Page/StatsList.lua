---
-- @Liquipedia
-- page=Module:Widget/Match/Page/StatsList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageStat
---@field icon string|Widget
---@field name string
---@field team1Value (string|Widget)|(string|Widget)[]
---@field team2Value (string|Widget)|(string|Widget)[]

---@class MatchPageStatsListParameters
---@field finished boolean
---@field data MatchPageStat[]

---@class MatchPageStatsList: Widget
---@operator call(MatchPageStatsListParameters): MatchPageStatsList
---@field props MatchPageStatsListParameters
local MatchPageStatsList = Class.new(Widget)

---@return Widget?
function MatchPageStatsList:render()
	if Logic.isEmpty(self.props.data) then return end
	return Div{
		classes = {'match-bm-team-stats-list'},
		children = Array.map(self.props.data, function (dataElement)
			return self:_renderStat(dataElement)
		end)
	}
end

---@param data MatchPageStat
---@return Widget?
function MatchPageStatsList:_renderStat(data)
	local finished = self.props.finished
	return Div{
		classes = {'match-bm-team-stats-list-row'},
		children = WidgetUtil.collect(
			finished and Div{
				classes = {'match-bm-team-stats-list-cell'},
				children = WidgetUtil.collect(data.team1Value)
			} or nil,
			Div{
				classes = {'match-bm-team-stats-list-cell', 'cell--middle'},
				children = {data.icon, data.name}
			},
			finished and Div{
				classes = {'match-bm-team-stats-list-cell'},
				children = WidgetUtil.collect(data.team2Value)
			} or nil
		)
	}
end

return MatchPageStatsList
