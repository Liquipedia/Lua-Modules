---
-- @Liquipedia
-- page=Module:Widget/VRSStandings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local MathUtil = Lua.import('Module:MathUtil')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')

local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Icon')

local VRSStandingsData = Lua.import('Module:VRSStandingsData')

local FOOTER_LINK = 'Valve_Regional_Standings'

local defaultProps = {
	title = 'VRS Standings',
	datapointType = 'LIVE',
}

---@param settings VRSStandingsSettings
---@return VNode[]
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
---@return VNode
local function buildHeaderRow(settings)
	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{children = buildHeaderCells(settings)}
		}
	}
end

---@param settings VRSStandingsSettings
---@return Table2ColumnDef[]
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
---@return VNode
local function buildTitle(settings)
	local regionMap = {
		AS = 'Asia',
		AM = 'Americas',
		EU = 'Europe'
	}
	local titleName = 'Global'
	if settings.filterType == 'region' then
		titleName = regionMap[settings.filterRegion] or settings.filterRegion or 'Region'
	elseif settings.filterType == 'subregion' then
		titleName = settings.filterDisplayName or 'Subregion'
	elseif settings.filterType == 'country' then
		titleName = settings.filterDisplayName or 'Country'
	end
	return Html.Div{
		children = {
			Html.Div{
				children = {
					Html.B{children = 'Unofficial ' .. titleName .. ' VRS'},
					Html.Span{children = 'Last updated: ' .. settings.updated}
				},
				classes = {'ranking-table__top-row-multiline'}
			},
			Html.Div{
				children = {
					Html.Span{children = 'Data by Liquipedia'},
				},
				classes = {'ranking-table__top-row-logo-container'}
			}
		},
		classes = {'ranking-table__top-row'},
	}
end

---@return VNode
local function buildFooter()
	return Link{
		link = FOOTER_LINK,
		linktype = 'internal',
		children = {
			Html.Div{
				children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
				classes = {'ranking-table__footer-button'},
			}
		},
	}
end

---@param standing VRSStandingsStanding
---@param mainpage boolean
---@return VNode
local function buildRow(standing, mainpage)
	local extradata = standing.opponent.extradata or {}

	local cells = WidgetUtil.collect(
		TableWidgets.Cell{children = standing.localPlace},
		standing.globalPlace and TableWidgets.Cell{children = standing.globalPlace} or nil,
		TableWidgets.Cell{
			children = MathUtil.formatRounded{value = standing.points, precision = 1}
		},
		TableWidgets.Cell{
			children = OpponentDisplay.InlineOpponent{
				opponent = standing.opponent
			}
		},
		not standing.globalPlace and TableWidgets.Cell{children = extradata.region or ''} or nil,
		not mainpage and TableWidgets.Cell{
			children = Array.map(standing.opponent.players, function(player)
				return Html.Div{
					css = {display = 'inline-block', width = '160px'},
					children = PlayerDisplay.BlockPlayer({player = player})
				}
			end)
		} or nil
	)

	return TableWidgets.Row{children = cells}
end

---@param props table<string|number, string>
---@return VNode
local function VRSStandings(props)
	local standings, settings = VRSStandingsData.getStandings(props)

	if #standings == 0 then
		return Html.Div{
			children = 'No teams found for the selected filter.',
			css = {['font-weight'] = 'bold', padding = '0.75rem'}
		}
	end

	return TableWidgets.Table{
		title = buildTitle(settings),
		sortable = false,
		columns = buildColumns(settings),
		footer = settings.mainpage and buildFooter() or nil,
		css = settings.mainpage and {width = '100%'} or nil,
		children = {
			buildHeaderRow(settings),
			TableWidgets.TableBody{
				children = Array.map(standings, function(entry)
					return buildRow(entry, settings.mainpage)
				end)
			}
		},
	}
end

return Component.component(VRSStandings, defaultProps)
