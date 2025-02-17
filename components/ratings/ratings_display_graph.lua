---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display/Graph
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

---@class RatingsDisplayGraph: RatingsDisplayInterface
local RatingsDisplayGraph = {}

local LIMIT_TEAMS = 10 -- How many teams to show in the combined graph
local LIMIT_TEAMS_SELECTED = 5 -- How many teams are preselected in the graph

---@param teamRankings RatingsEntry[]
---@return string
function RatingsDisplayGraph.build(teamRankings)
	local teams = Array.sub(teamRankings, 1, LIMIT_TEAMS)

	return mw.ext.Charts.chart({
		xAxis = {
			type = 'category',
			data = Array.map(teams[1].progression or {}, Operator.property('date'))
		},
		yAxis = {
			name = 'Rating',
			type = 'value',
			min = 1500,
			max = 3500,
			axisTick = {
				interval = 500
			}
		},
		tooltip = {
			trigger = 'axis'
		},
		grid = {
			show = true
		},
		size = {
			height = 500,
			width = 700
		},
		legend = {
			show = true,
			selected = Table.map(teams, function(rank, team)
				return team.shortName, rank <= LIMIT_TEAMS_SELECTED and true or false
			end)
		},
		series = Array.map(teams, function(team)
			return {
				data = Array.map(team.progression, Operator.property('rating')),
				type = 'line',
				name = team.shortName
			}
		end)
	})
end

return RatingsDisplayGraph
