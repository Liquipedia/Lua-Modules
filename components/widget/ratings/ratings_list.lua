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
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local OpponentLibraries = require('Module:OpponentLibraries')
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
	showGraph = true,
}

---@param teamData RatingsEntry
---@param stanardYMax integer
---@return string
local function makeTeamChart(teamData, stanardYMax)
	local progression = Array.reverse(teamData.progression) -- TODO: Sort instead
	local worstRankOfTeam = Array.max(Array.map(progression, Operator.property('rank')))
	return mw.ext.Charts.chart{
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
			max = math.max(worstRankOfTeam, stanardYMax),
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
				name = 'Rank',
			}
		}
	}
end

---@return Widget
function RatingsList:render()
	local parsedDate = Date.parseIsoDate(self.props.date)
	if not parsedDate then
		error('Invalid date provided')
	end

	local teamLimit = tonumber(self.props.teamLimit) or self.defaultProps.teamLimit
	local progressionLimit = tonumber(self.props.progressionLimit) or self.defaultProps.progressionLimit
	local showGraph = Logic.readBool(self.props.showGraph)

	local getRankings = RatingsStorageFactory.createGetRankings{
		storageType = self.props.storageType,
		date = self.props.date,
		id = self.props.id,
	}
	local teams = getRankings(teamLimit, progressionLimit)

	local teamRows = Array.map(teams, function(team, rank)
		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
				or (team.streak < -1 and 'group-table-rank-change-down')
				or nil

		local changeText = (not team.change and 'NEW') or PlacementChange{change = team.change}

		local teamRow = WidgetUtil.collect(
			HtmlWidgets.Td{children = rank},
			HtmlWidgets.Td{children = changeText},
			HtmlWidgets.Td{children = OpponentDisplay.InlineOpponent{opponent = team.opponent}},
			HtmlWidgets.Td{children = team.rating},
			HtmlWidgets.Td{children = Flags.Icon(team.region) .. Flags.CountryName(team.region)},
			HtmlWidgets.Td{children = streakText, classes = {streakClass}},
			showGraph and (HtmlWidgets.Td{children = HtmlWidgets.Span{
				attributes = { class = 'toggle-graph' },
				children = Icon.makeIcon { iconName = 'expand' }
			}}) or nil
		)

		local graphRow = showGraph and {
			HtmlWidgets.Td{
				attributes = {colspan = '7'},
				children = HtmlWidgets.Div{
					children = {
						OpponentDisplay.InlineOpponent{opponent = team.opponent},
						makeTeamChart(team, teamLimit),
					},
					classes = {'ranking-table__graph-row-container'}
				}
			}
		} or nil

		local isEven = rank % 2 == 0
		local rowClasses = {'ranking-table__row'}
		if isEven then
			table.insert(rowClasses, 'ranking-table__row--even')
		end

		return {
			HtmlWidgets.Tr{children = teamRow, classes = rowClasses},
			showGraph and HtmlWidgets.Tr{children = graphRow, classes = {'ranking-table__graph-row'}} or nil
		}
	end)

	local formattedDate = os.date('%b %d, %Y', os.time(parsedDate)) --[[@as string]]
	local tableHeader = HtmlWidgets.Tr{
		children = HtmlWidgets.Th{
			attributes = {colspan = '7'},
			children = HtmlWidgets.Div{
				children = { 'Last updated: ' .. formattedDate, '[[File:DataProvidedSAP.svg|link=]]' }
			},
			classes = {'ranking-table__top-row'},
		}
	}

	return HtmlWidgets.Table{ classes = {'ranking-table'}, children = WidgetUtil.collect(
		tableHeader,
		HtmlWidgets.Tr{
			children = WidgetUtil.collect(
				HtmlWidgets.Th{children = 'Rank'},
				HtmlWidgets.Th{children = '+/-'},
				HtmlWidgets.Th{children = 'Team'},
				HtmlWidgets.Th{children = 'Points'},
				HtmlWidgets.Th{children = 'Region'},
				HtmlWidgets.Th{children = 'Streak'},
				showGraph and HtmlWidgets.Th{children = Icon.makeIcon{iconName='chart'}} or nil
			),
			classes = {'ranking-table__header-row'},
		},
		Array.flatMap(teamRows, FnUtil.identity)
	)}
end

return RatingsList
