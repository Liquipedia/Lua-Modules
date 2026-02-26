---
-- @Liquipedia
-- page=Module:Widget/Ratings/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local RatingsStorageFactory = Lua.import('Module:Ratings/Storage/Factory')

---@class RatingsList: Widget
---@field _base Widget
---@operator call(table): RatingsList
local RatingsList = Class.new(Widget)

---@param teamData RatingsEntry
---@param defaultMaxY integer
---@return string
local function makeTeamChart(teamData, defaultMaxY)
	local progression = Array.sortBy(teamData.progression, Operator.property('date'))
	local worstRankOfTeam = Array.max(Array.map(progression, Operator.property('rank')))

	local dates = Array.map(Array.map(progression, Operator.property('date')), function(isoDate)
		return os.date('%b %d', os.time(Date.parseIsoDate(isoDate)))
	end)

	return mw.ext.Charts.chart {
		xAxis = {
			name = 'Date',
			nameLocation = 'middle',
			type = 'category',
			data = dates,
		},
		yAxis = {
			name = 'Rank',
			nameLocation = 'middle',
			nameRotate = 90,
			type = 'value',
			inverse = true,
			min = 1,
			max = math.max(worstRankOfTeam, defaultMaxY),
		},
		tooltip = {
			trigger = 'axis',
		},
		grid = {
			show = true,
		},
		size = {
			height = 250,
			pwidth = 100,
		},
		series = {
			{
				data = Array.map(progression, function(progress)
					return progress.rank and tostring(progress.rank) or ''
				end),
				type = 'line',
				name = 'Rank',
				symbolSize = 8,
				itemStyle = {
					color = '#EE6666',
				},
			}
		}
	}
end

---@return Widget
function RatingsList:render()
	local teamLimit = tonumber(self.props.teamLimit) or self.defaultProps.teamLimit
	local showGraph = Logic.readBool(self.props.showGraph)
	local isSmallerVersion = Logic.readBool(self.props.isSmallerVersion)

	local getRankings = RatingsStorageFactory.createGetRankings {
		storageType = self.props.storageType,
		id = self.props.id,
	}
	local teams = getRankings(teamLimit)

	local teamRows = Array.map(teams, function(team, index)
		local uniqueId = index
		local changeText = (not team.change and 'NEW') or PlacementChange { change = team.change }

		local teamRow = WidgetUtil.collect(
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = team.rank },
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'change' }, children = changeText },
			HtmlWidgets.Td {
				attributes = { ['data-ranking-table-cell'] = 'team' },
				children = OpponentDisplay.BlockOpponent { opponent = team.opponent, teamStyle = 'hybrid' }
			},
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'rating' }, children = MathUtil.round(team.rating) },
			HtmlWidgets.Td {
				attributes = { ['data-ranking-table-cell'] = 'region' },
				children = Flags.Icon { flag = team.region } .. Flags.CountryName { flag = team.region }
			},
			showGraph and (HtmlWidgets.Td {
				attributes = {
					class = 'ranking-table__toggle-graph-cell',
					['data-ranking-table-cell'] = 'graph'
				},
				children = HtmlWidgets.Span {
					attributes = {
						class = 'ranking-table__toggle-graph',
						['data-ranking-table'] = 'toggle',
						['data-ranking-table-id'] = uniqueId,
						['aria-controls'] = uniqueId,
						tabindex = '1'
					},
					children = Icon.makeIcon { iconName = 'expand' }
				} }) or nil
		)

		local graphRow = showGraph and {
			HtmlWidgets.Td {
				attributes = {
					colspan = '7',
					['data-ranking-table-cell'] = 'graph'
				},
				children = HtmlWidgets.Div {
					children = {
						OpponentDisplay.InlineOpponent { opponent = team.opponent },
						Logic.tryOrElseLog(
							function() return makeTeamChart(team, teamLimit) end,
							function() return 'Failed to make graph for team' end
						)
					},
					classes = { 'ranking-table__graph-row-container' }
				}
			}
		} or nil

		local isEven = team.rank % 2 == 0
		local rowClasses = { 'ranking-table__row' }
		if isEven then
			table.insert(rowClasses, 'ranking-table__row--even')
		end
		if team.rank > 5 and isSmallerVersion then
			table.insert(rowClasses, 'ranking-table__row--overfive')
		end

		return {
			HtmlWidgets.Tr { children = teamRow, classes = rowClasses },
			showGraph and HtmlWidgets.Tr {
				children = graphRow,
				classes = { 'ranking-table__graph-row d-none' },
				attributes = {
					['data-ranking-table'] = 'graph-row',
					['aria-expanded'] = 'false',
					['data-ranking-table-id'] = uniqueId
				},
			} or nil
		}
	end)

	local anyTeam = teams[1]
	local lastDate = anyTeam.progression[#anyTeam.progression].date
	local formattedDate = Date.toYmdInUtc(Date.parseIsoDate(lastDate))

	local tableHeader = HtmlWidgets.Tr {
		children = HtmlWidgets.Th {
			attributes = { colspan = '7' },
			children = HtmlWidgets.Div {
				children = {
					HtmlWidgets.Div {
						children = {
							HtmlWidgets.B { children = 'BETA' },
							HtmlWidgets.Span { children = 'Last updated: ' .. formattedDate }
						},
						classes = { 'ranking-table__top-row-text' }
					},
					HtmlWidgets.Div {
						children = {
							HtmlWidgets.Span { children = 'Data provided by ' },
							HtmlWidgets.Div { children = '[[File:SAP_logo.svg|link=|SAP]]' }
						},
						classes = { 'ranking-table__top-row-logo-container' }
					}
				}
			},
			classes = { 'ranking-table__top-row' },
		}
	}

	local buttonDiv = HtmlWidgets.Div {
		children = { 'See Rankings Page', Icon.makeIcon { iconName = 'goto' } },
	}

	local tableFooter = HtmlWidgets.Tr {
		children = HtmlWidgets.Th {
			attributes = { colspan = '7' },
			children = Link {
				link = 'Portal:Rankings',
				linktype = 'internal',
				children = { buttonDiv },
			},
			classes = { 'ranking-table__footer-row' },
		}
	}

	return HtmlWidgets.Div {
		attributes = {
			['data-ranking-table'] = 'content',
		},
		children = WidgetUtil.collect(
			HtmlWidgets.Table {
				attributes = { ['data-ranking-table'] = 'table' },
				classes = { 'ranking-table', isSmallerVersion and 'ranking-table--small' or nil },
				children = WidgetUtil.collect(
					tableHeader,
					HtmlWidgets.Tr {
						children = WidgetUtil.collect(
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = 'Rank' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'change' }, children = '+/-' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'team' }, children = 'Team' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'rating' }, children = 'Points' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'region' }, children = 'Region' },
							showGraph and HtmlWidgets.Th {
								attributes = { ['data-ranking-table-cell'] = 'graph' },
								children = Icon.makeIcon { iconName = 'chart' }
							} or nil
						),
						classes = { 'ranking-table__header-row' },
					},
					Array.flatten(teamRows),
					isSmallerVersion and tableFooter or nil
				)
			}
		)
	}
end

return RatingsList
