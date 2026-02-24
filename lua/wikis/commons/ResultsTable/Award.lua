---
-- @Liquipedia
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local LeagueIcon = Lua.import('Module:LeagueIcon')

local Opponent = Lua.import('Module:Opponent/Custom')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')

local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AwardsTable: BaseResultsTable
---@operator call(table): AwardsTable
local AwardsTable = Class.new(BaseResultsTable)

function AwardsTable:buildColumnDefinitions()
	return WidgetUtil.collect(
		{
			align = 'center',
			sortType = 'isoDate',
		},
		{
			align = 'center',
			minWidth = '75px',
		},
		self.config.showType and {
			align = 'center',
			minWidth = '50px',
		} or nil,
		{align = 'center'},
		{align = 'center'},
		{
			align = 'center',
			minWidth = '225px',
		},
		self.config.queryType ~= Opponent.team and {
			align = 'center',
			minWidth = '70px',
		} or self.config.playerResultsOfTeam and {
			align = 'center',
			minWidth = '105px',
		} or nil,
		{
			align = 'center',
			sortType = 'currency',
		}
	)
end

---Builds the Header of the award table
---@return Widget
function AwardsTable:buildHeader()
	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Date'},
		TableWidgets.CellHeader{children = 'Tier'},
		self.config.showType and TableWidgets.CellHeader{children = 'Type'} or nil,
		TableWidgets.CellHeader{
			colspan = 2,
			children = 'Tournament'
		},
		TableWidgets.CellHeader{children = 'Award'},
		self.config.queryType ~= Opponent.team and TableWidgets.CellHeader{
			children = 'Team'
		} or self.config.playerResultsOfTeam and TableWidgets.CellHeader{
			children = 'Player'
		} or nil,
		TableWidgets.CellHeader{children = 'Prize'}
	)}
end

---Builds a row of the award table
---@param placement placement
---@return Widget
function AwardsTable:buildRow(placement)
	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)

	return TableWidgets.Row{
		highlighted = self:rowHighlight(placement),
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = DateExt.toYmdInUtc(placement.date)},
			TableWidgets.Cell{
				attributes = {
					['data-sort-value'] = tierSortValue
				},
				children = tierDisplay
			},
			self.config.showType and TableWidgets.Cell{
				children = placement.type
			} or nil,
			TableWidgets.Cell{
				attributes = {
					['data-sort-value'] = tournamentDisplayName
				},
				css = {width = '30px'},
				children = LeagueIcon.display{
					icon = placement.icon,
					iconDark = placement.icondark,
					link = placement.parent,
					name = tournamentDisplayName,
					options = {noTemplate = true},
				}
			},
			TableWidgets.Cell{
				attributes = {
					['data-sort-value'] = tournamentDisplayName
				},
				children = LinkWidget{
					children = tournamentDisplayName,
					link = placement.pagename,
				}
			},
			TableWidgets.Cell{children = placement.extradata.award},
			(self.config.playerResultsOfTeam or self.config.queryType ~= Opponent.team) and TableWidgets.Cell{
				attributes = {
					['data-sort-value'] = placement.opponentname
				},
				children = self:opponentDisplay(
					placement,
					{teamForSolo = not self.config.playerResultsOfTeam}
				)
			} or nil,
			TableWidgets.Cell{children = Currency.display('USD',
				self.config.queryType ~= Opponent.team and placement.individualprizemoney or placement.prizemoney,
				{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
			)}
		)
	}
end

return AwardsTable
