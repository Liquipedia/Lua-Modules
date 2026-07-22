---
-- @Liquipedia
-- page=Module:Widget/Match/Page/StatsList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageStat
---@field icon Renderable
---@field name string
---@field team1Value? Renderable|Renderable[]
---@field team2Value? Renderable|Renderable[]

---@class MatchPageStatsListParameters
---@field finished boolean
---@field data MatchPageStat[]

local MatchPageStatsList = {}

---@param props MatchPageStatsListParameters
---@return VNode?
function MatchPageStatsList.render(props)
	if Logic.isEmpty(props.data) then
		return
	end
	return Div{
		classes = {'match-bm-team-stats-list'},
		children = Array.map(
			Array.filter(props.data, function (element)
				return Logic.isNotEmpty(element.team1Value) or Logic.isNotEmpty(element.team2Value)
			end),
			FnUtil.curry(MatchPageStatsList._renderStat, props.finished)
		)
	}
end

---@param finished boolean
---@param data MatchPageStat
---@return VNode
function MatchPageStatsList._renderStat(finished, data)
	return Div{
		classes = {'match-bm-team-stats-list-row'},
		children = WidgetUtil.collect(
			finished and Div{
				classes = {'match-bm-team-stats-list-cell'},
				children = data.team1Value
			} or nil,
			Div{
				classes = {'match-bm-team-stats-list-cell', 'cell--middle'},
				children = WidgetUtil.collect(data.icon, data.name)
			},
			finished and Div{
				classes = {'match-bm-team-stats-list-cell'},
				children = data.team2Value
			} or nil
		)
	}
end

return Component.component(MatchPageStatsList.render)
