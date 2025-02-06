---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Template = require('Module:Template')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local RatingsStorageFactory = Lua.import('Module:Ratings/Storage/Factory')

---@class RatingsList: Widget
---@operator call(table): RatingsList
local RatingsList = Class.new(Widget)
RatingsList.defaultProps = {
	teamLimit = 20,
	progressionLimit = 10,
	storageType = 'lpdb',
	date = Date.getContextualDateOrNow(),
}

---@return Widget
function RatingsList:render()
	local teamLimit = tonumber(self.props.teamLimit) or self.defaultProps.teamLimit
	local getRankings = RatingsStorageFactory.createGetRankings{
		storageType = self.props.storageType,
		date = self.props.date,
		id = self.props.id,
	}
	local teams = getRankings(teamLimit, self.props.progressionLimit)

	local teamRows = Array.map(teams, function(team, rank)
		local chart = mw.ext.Charts.chart{
			xAxis = {
				type = 'category',
				data = Array.map(team.progression, Operator.property('date'))
			},
			yAxis = {
				type = 'value',
				min = 1000,
				max = 3500,
			},
			tooltip = {
				trigger = 'axis'
			},
			grid = {
				show = true
			},
			size = {
				height = 300,
				width = 500
			},
			series = {
				{
					data = Array.map(team.progression, Operator.property('rating')),
					type = 'line'
				}
			}
		}

		local popup = Template.safeExpand(mw.getCurrentFrame(), 'Popup', {
			label = 'show',
			title = 'Details for ' .. OpponentDisplay.InlineOpponent{opponent = team.opponent},
			content = chart,
		})

		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
				or (team.streak < -1 and 'group-table-rank-change-down')
				or nil

		return {
			HtmlWidgets.Td{children = rank},
			HtmlWidgets.Td{children = OpponentDisplay.InlineOpponent{opponent = team.opponent}},
			HtmlWidgets.Td{children = math.floor(team.rating + 0.5)},
			HtmlWidgets.Td{children = string.upper(team.region or '')},
			HtmlWidgets.Td{children = streakText, classes = {streakClass}},
			HtmlWidgets.Td{children = popup},
		}
	end)

	return DataTable{children = WidgetUtil.collect(
		HtmlWidgets.Tr{
			children = Array.map({ '#', 'Team', 'Rating', 'Region', 'Streak', 'History' }, function(title)
				return HtmlWidgets.Th{children = title}
			end),
		},
		Array.map(teamRows, function(teamCells)
			return HtmlWidgets.Tr{children = teamCells}
		end)
	)}
end

return RatingsList
