---
-- @Liquipedia
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')
local Class = Lua.import('Module:Class')
local Opponent = Lua.import('Module:Opponent/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AwardsTable: BaseResultsTable
---@operator call(table): AwardsTable
local AwardsTable = Class.new(BaseResultsTable)

---@protected
---@return table[]
function AwardsTable:buildColumnDefinitions()
	return WidgetUtil.collect(
		{
			align = 'left',
			sortType = 'isoDate',
		},
		{align = 'left'},
		self.config.showType and {
			align = 'center',
		} or nil,
		{align = 'left'},
		{align = 'left'},
		{align = 'left'},
		self.config.queryType ~= Opponent.team and {
			align = 'center',
		} or self.config.playerResultsOfTeam and {
			align = 'center',
		} or nil,
		{
			align = 'right',
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
	return TableWidgets.Row{
		highlighted = self:rowHighlight(placement),
		children = WidgetUtil.collect(
			self:createDateCell(placement),
			self:createTierCell(placement),
			self:createTypeCell(placement),
			self:createTournamentCells(placement),
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
			self:createPrizeCell{placement = placement}
		)
	}
end

return AwardsTable
