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
local Flags = require('Module:Flags')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
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
	local parsedDate = Date.parseIsoDate(self.props.date)
	if not parsedDate then
		error('Invalid date provided')
	end

	local teamLimit = tonumber(self.props.teamLimit) or self.defaultProps.teamLimit
	local progressionLimit = tonumber(self.props.progressionLimit) or self.defaultProps.progressionLimit
	local getRankings = RatingsStorageFactory.createGetRankings{
		storageType = self.props.storageType,
		date = self.props.date,
		id = self.props.id,
	}
	local teams = getRankings(teamLimit, progressionLimit)

	local teamRows = Array.map(teams, function(team, rank)
		local progression = Array.reverse(team.progression)
		local worstRankOfTeam = Array.max(Array.map(progression, Operator.property('rank')))
		local chart = mw.ext.Charts.chart{
			xAxis = {
				name = 'Date',
				nameLocation = 'middle',
				type = 'category',
				data = Array.map(progression, Operator.property('date')),
			},
			yAxis = {
				name = 'Rank',
				nameLocation = 'middle',
				nameRotate = 90,
				type = 'value',
				inverse = true,
				min = 1,
				max = math.max(worstRankOfTeam, teamLimit),
			},
			tooltip = {
				trigger = 'axis',
			},
			grid = {
				show = true,
			},
			size = {
				height = 300,
				pwidth = 100,
			},
			series = {
				{
					data = Array.map(progression, function(progress)
						return progress.rank and tostring(progress.rank) or ''
					end),
					type = 'line',
					name = Opponent.toName(team.opponent),
				}
			}
		}

		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
				or (team.streak < -1 and 'group-table-rank-change-down')
				or nil

		local changeText = (not team.change and 'NEW') or PlacementChange{change = team.change}

		local teamRow = {
			HtmlWidgets.Td{children = rank},
			HtmlWidgets.Td{children = changeText},
			HtmlWidgets.Td{children = OpponentDisplay.InlineOpponent{opponent = team.opponent}},
			HtmlWidgets.Td{children = team.rating},
			HtmlWidgets.Td{children = Flags.Icon(team.region) .. Flags.CountryName(team.region)},
			HtmlWidgets.Td{children = streakText, classes = {streakClass}},
			HtmlWidgets.Td{children = HtmlWidgets.Span{
				attributes = { class = 'toggle-graph' },
				children = Icon.makeIcon { iconName = 'expand' }
			}},
		}

		local graphRow = {
			HtmlWidgets.Td{
				attributes = {colspan = '7'},
				children = { OpponentDisplay.InlineOpponent{opponent = team.opponent}, chart },
				classes = {'graph-row-td'}
			}
		}

		return {
			teamRow, graphRow
		}
	end)

	local formattedDate = os.date('%b %d, %Y', os.time(parsedDate)) --[[@as string]]
	local tableHeader = HtmlWidgets.Tr{
		children = HtmlWidgets.Th{
			attributes = {colspan = '7'},
			children = { 'Last updated: ' .. formattedDate, '[[File:DataProvidedSAP.svg|link=]]' },
			classes = {'ranking-table__top-row'},
		}
	}

	return HtmlWidgets.Table{ classes = {'ranking-table'}, children = WidgetUtil.collect(
		tableHeader,
		HtmlWidgets.Tr{
			children = Array.map({ 'Rank', '+/-', 'Team', 'Points', 'Region', 'Streak', Icon.makeIcon{iconName='chart'} }, function(title)
				return HtmlWidgets.Th{children = title}
			end),
			classes = {'ranking-table__header-row'},
		},
		Array.flatMap(teamRows, function(rows)
			return {
				HtmlWidgets.Tr{children = rows[1]},
				HtmlWidgets.Tr{children = rows[2], classes = {'graph-row', 'hidden'}}
			}
		end)
	)}
end

return RatingsList
