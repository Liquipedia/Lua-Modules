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
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local RatingsStorageFactory = Lua.import('Module:Ratings/Storage/Factory')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

---@class RatingsList: Widget
---@field _base Widget
---@operator call(table): RatingsList
local RatingsList = Class.new(Widget)

local GRAPH_VIEW_RANK = 'rank'
local GRAPH_VIEW_POINTS = 'points'
local GRAPH_COLOR_RANK = '#EE6666'
local GRAPH_COLOR_POINTS = '#2F80ED'

---@alias RatingsProgression {date: string, rating: number?, rank: integer?}[]
---@alias AxisBoundsFn fun(progression: RatingsProgression, defaultMaxY: integer): number, number

---@param progression RatingsProgression
---@return number
---@return number
local function pointsAxisBounds(progression)
	local points = Array.filter(Array.map(progression, Operator.property('rating')), Logic.isNotEmpty)
	local minPoints = Array.min(points) or 0
	local maxPoints = Array.max(points) or minPoints
	local roundedMinPoints = math.max(0, math.floor(minPoints))
	local roundedMaxPoints = math.ceil(maxPoints)

	if roundedMinPoints == roundedMaxPoints then
		return math.max(0, roundedMinPoints - 1), roundedMaxPoints + 1
	end

	return roundedMinPoints, roundedMaxPoints
end

---@param progression RatingsProgression
---@param defaultMaxY integer
---@return number
---@return number
local function rankAxisBounds(progression, defaultMaxY)
	local worstRank = Array.max(Array.map(progression, Operator.property('rank'))) or defaultMaxY
	return 1, math.max(worstRank, defaultMaxY)
end

---@param progression {date: string, rating: number?, rank: integer?}[]
---@param graphView string
---@return (number|string)[]
local function makeGraphSeriesData(progression, graphView)
	return Array.map(progression, function(progress)
		local value = graphView == GRAPH_VIEW_POINTS and progress.rating or progress.rank
		return value or ''
	end)
end

---@param teamData RatingsEntry
---@param defaultMaxY integer
---@param graphView string
---@param getAxisBounds AxisBoundsFn
---@return string
local function makeTeamChart(teamData, defaultMaxY, graphView, getAxisBounds)
	local progression = Array.sortBy(teamData.progression, Operator.property('date'))
	local axisMin, axisMax = getAxisBounds(progression, defaultMaxY)
	local axisName = graphView == GRAPH_VIEW_POINTS and 'Points' or 'Rank'
	local graphColor = graphView == GRAPH_VIEW_POINTS and GRAPH_COLOR_POINTS or GRAPH_COLOR_RANK

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
			name = axisName,
			nameLocation = 'middle',
			nameRotate = 90,
			type = 'value',
			inverse = graphView == GRAPH_VIEW_RANK,
			min = axisMin,
			max = axisMax,
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
				data = makeGraphSeriesData(progression, graphView),
				type = 'line',
				name = axisName,
				symbolSize = 8,
				color = graphColor,
				itemStyle = {
					color = graphColor,
					borderColor = '#FFFFFF',
					borderWidth = 2,
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

	local anyTeam = teams[1]
	local lastDate = anyTeam.progression[#anyTeam.progression].date
	local formattedDate = Date.toYmdInUtc(Date.parseIsoDate(lastDate))

	local columns = {
		{ align = 'right' },
		{ align = 'left' },
		{ align = 'left' },
		{ align = 'right' },
		{ align = 'left' },
		{ align = 'center' },
	}

	local title = HtmlWidgets.Div {
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
					IconImage { imageLight = 'SAP_logo.svg', size = '90px' }
				},
				classes = { 'ranking-table__top-row-logo-container' }
			}
		},
		classes = { 'ranking-table__top-row' },
	}

	local columnHeaderRow = TableWidgets.Row {
		children = WidgetUtil.collect(
			TableWidgets.CellHeader { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = 'Rank' },
			TableWidgets.CellHeader { attributes = { ['data-ranking-table-cell'] = 'change' }, children = '+/-' },
			TableWidgets.CellHeader { attributes = { ['data-ranking-table-cell'] = 'team' }, children = 'Team' },
			TableWidgets.CellHeader { attributes = { ['data-ranking-table-cell'] = 'rating' }, children = 'Points' },
			TableWidgets.CellHeader { attributes = { ['data-ranking-table-cell'] = 'region' }, children = 'Region' },
			showGraph and TableWidgets.CellHeader {
				attributes = { ['data-ranking-table-cell'] = 'graph' },
				children = Icon.makeIcon { iconName = 'chart' }
			} or nil
		),
	}

	local teamRows = Array.map(teams, function(team, index)
		local uniqueId = index
		local graphSwitchGroup = 'ratings-graph-view-' .. tostring(self.props.id or 'default') .. '-' .. uniqueId
		local changeText = (not team.change and 'NEW') or PlacementChange { change = team.change }

		local rowClasses = {}
		local isEven = team.rank % 2 == 0
		if isEven then
			table.insert(rowClasses, 'ranking-table__row--even')
		end
		if team.rank > 5 and isSmallerVersion then
			table.insert(rowClasses, 'ranking-table__row--overfive')
		end

		local teamRowCells = WidgetUtil.collect(
			TableWidgets.Cell { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = team.rank },
			TableWidgets.Cell { attributes = { ['data-ranking-table-cell'] = 'change' }, children = changeText },
			TableWidgets.Cell {
				attributes = { ['data-ranking-table-cell'] = 'team' },
				children = OpponentDisplay.BlockOpponent { opponent = team.opponent, teamStyle = 'hybrid' }
			},
			TableWidgets.Cell {
				attributes = { ['data-ranking-table-cell'] = 'rating' },
				children = MathUtil.round(team.rating)
			},
			TableWidgets.Cell {
				attributes = { ['data-ranking-table-cell'] = 'region' },
				children = Flags.Icon { flag = team.region } .. Flags.CountryName { flag = team.region }
			},
			showGraph and TableWidgets.Cell {
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
				} } or nil
		)

		local teamRow = TableWidgets.Row {
			children = teamRowCells,
			classes = rowClasses,
		}

		local graphRow = nil
		if showGraph then
			graphRow = TableWidgets.Row {
				children = TableWidgets.Cell {
					attributes = {
						colspan = '6',
						['data-ranking-table-cell'] = 'graph'
					},
					children = HtmlWidgets.Div {
						children = {
							HtmlWidgets.Div {
								classes = { 'ranking-table__graph-switch' },
								children = ContentSwitch {
									switchGroup = graphSwitchGroup,
									storeValue = false,
									defaultActive = 1,
									css = { display = 'flex', ['justify-self'] = 'center' },
									tabs = {
										{
											label = 'Rank',
											value = GRAPH_VIEW_RANK,
											content = Logic.tryOrElseLog(
												function()
													return makeTeamChart(team, teamLimit, GRAPH_VIEW_RANK, rankAxisBounds)
												end,
												function() return 'Failed to make rank graph for team' end
											)
										},
										{
											label = 'Points',
											value = GRAPH_VIEW_POINTS,
											content = Logic.tryOrElseLog(
												function()
													return makeTeamChart(team, teamLimit, GRAPH_VIEW_POINTS, pointsAxisBounds)
												end,
												function() return 'Failed to make points graph for team' end
											)
										},
									},
								},
							}
						}
					},
					classes = { 'ranking-table__graph-row-container' }
				},
				classes = { 'ranking-table__graph-row d-none' },
				attributes = {
					['data-ranking-table'] = 'graph-row',
					['aria-expanded'] = 'false',
					['data-ranking-table-id'] = uniqueId
				},
			}
		end

		return {
			teamRow,
			graphRow
		}
	end)

	local buttonDiv = HtmlWidgets.Div {
		children = { 'See Rankings Page', Icon.makeIcon { iconName = 'goto' } },
		classes = { 'ranking-table__footer-button' },
	}

	local footer = Link {
		link = 'Portal:Rankings',
		linktype = 'internal',
		children = { buttonDiv },
	}

	return HtmlWidgets.Div {
		attributes = {
			['data-ranking-table'] = 'content',
		},
		children = TableWidgets.Table {
			columns = columns,
			striped = false,
			title = title,
			footer = isSmallerVersion and footer or nil,
			classes = { isSmallerVersion and 'ranking-table--small' or nil },
			tableAttributes = { ['data-ranking-table'] = 'table' },
			tableClasses = { 'ranking-table' },
			children = WidgetUtil.collect(
				TableWidgets.TableHeader {
					children = { columnHeaderRow }
				},
				TableWidgets.TableBody {
					children = Array.flatten(teamRows)
				}
			)
		}
	}
end

return RatingsList
