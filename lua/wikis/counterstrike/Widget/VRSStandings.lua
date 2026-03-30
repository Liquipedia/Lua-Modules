---
-- @Liquipedia
-- page=Module:Widget/VRSStandings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Icon')

local VRSStandingsData = Lua.import('Module:VRSStandingsData')

local FOOTER_LINK = 'Valve_Regional_Standings'

---@class VRSStandings: Widget
---@operator call(table): VRSStandings
---@field props table<string|number, string>
local VRSStandings = Class.new(Widget)
VRSStandings.defaultProps = {
	title = 'VRS Standings',
	datapointType = 'LIVE',
}

---@param settings VRSStandingsSettings
---@return Widget[]
local function buildHeaderCells(settings)
	local filtered = settings.filterType ~= 'none'
	return WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Rank'},
		filtered and TableWidgets.CellHeader{children = 'Global Rank'} or nil,
		TableWidgets.CellHeader{children = 'Points'},
		TableWidgets.CellHeader{children = 'Team'},
		not filtered and TableWidgets.CellHeader{children = 'Region'} or nil,
		not settings.mainpage and TableWidgets.CellHeader{children = 'Roster'} or nil
	)
end

---@param settings VRSStandingsSettings
---@return Widget
local function buildHeaderRow(settings)
	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{children = buildHeaderCells(settings)}
		}
	}
end

---@param settings VRSStandingsSettings
---@return table[]
local function buildColumns(settings)
	local filtered = settings.filterType ~= 'none'
	local columns = WidgetUtil.collect(
		{align = 'center', sortType = 'number'},
		filtered and {align = 'center', sortType = 'number'} or nil,
		{align = 'center', sortType = 'number'},
		{align = 'left'},
		not filtered and {align = 'center'} or nil,
		not settings.mainpage and {align = 'left'} or nil
	)
	if settings.mainpage then
		Array.forEach(columns, function(col)
			col.width = (100 / #columns) .. '%'
		end)
	end
	return columns
end

---@param settings VRSStandingsSettings
---@return Widget
local function buildTitle(settings)
	local regionMap = {
		AS = 'Asia',
		AM = 'Americas',
		EU = 'Europe'
	}
	local titleName = 'Global'
	if settings.filterType == 'region' then
		titleName = regionMap[settings.filterRegion] or settings.filterRegion
	elseif settings.filterType == 'subregion' then
		titleName = settings.filterDisplayName or 'Subregion'
	elseif settings.filterType == 'country' then
		titleName = settings.filterDisplayName or 'Country'
	end
	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Div{
				children = {
					HtmlWidgets.B{children = 'Unofficial ' .. titleName .. ' VRS'},
					HtmlWidgets.Span{children = 'Last updated: ' .. settings.updated}
				},
				classes = {'ranking-table__top-row-text'}
			},
			HtmlWidgets.Div{
				children = {
					HtmlWidgets.Span{children = 'Data by Liquipedia'},
				},
				classes = {'ranking-table__top-row-logo-container'}
			}
		},
		classes = {'ranking-table__top-row'},
	}
end

---@return Widget
local function buildFooter()
	return Link{
		link = FOOTER_LINK,
		linktype = 'internal',
		children = {
			HtmlWidgets.Div{
				children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
				classes = {'ranking-table__footer-button'},
			}
		},
	}
end

---@param standing VRSStandingsStanding
---@param mainpage boolean
---@return Widget
function VRSStandings._row(standing, mainpage)
	local extradata = standing.opponent.extradata or {}

	local cells
	cells = WidgetUtil.collect(
		TableWidgets.Cell{children = standing.local_place},
		standing.global_place and TableWidgets.Cell{children = standing.global_place} or nil,
		TableWidgets.Cell{
			children = MathUtil.formatRounded{value = standing.points, precision = 1}
		},
		TableWidgets.Cell{
			children = OpponentDisplay.InlineOpponent{
				opponent = standing.opponent
			}
		},
		not standing.global_place and TableWidgets.Cell{children = extradata.region or ''} or nil
	)

	if not mainpage then
		table.insert(cells,
			TableWidgets.Cell{
				children = Array.map(standing.opponent.players, function(player)
					return HtmlWidgets.Span{
						css = {display="inline-block", width="160px"},
						children = PlayerDisplay.BlockPlayer({player = player})
					}
				end)
			}
		)
	end

	return TableWidgets.Row{children = cells}
end

---@return Widget
function VRSStandings:render()
	local standings, settings = VRSStandingsData.getStandings(self.props)

	if #standings == 0 then
		return HtmlWidgets.Div{
			children = {
				HtmlWidgets.B{children = 'No teams found for the selected filter.'}
			},
			css = {padding = '12px'}
		}
	end

	local tableWidget = TableWidgets.Table{
		title = buildTitle(settings),
		sortable = false,
		columns = buildColumns(settings),
		footer = settings.mainpage and buildFooter() or nil,
		css = settings.mainpage and {width = '100%'} or nil,
		children = {
			buildHeaderRow(settings),
			TableWidgets.TableBody{
				children = Array.map(standings, function(entry)
					return VRSStandings._row(entry, settings.mainpage)
				end)
			}
		},
	}
	return tableWidget
end

return VRSStandings
