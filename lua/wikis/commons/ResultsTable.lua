---
-- @Liquipedia
-- page=Module:ResultsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Opponent = Lua.import('Module:Opponent/Custom')
local Placement = Lua.import('Module:Placement')
local Table = Lua.import('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ResultsTable: BaseResultsTable
---@operator call(table): ResultsTable
local ResultsTable = Class.new(BaseResultsTable)

---@protected
---@return table[]
function ResultsTable:buildColumnDefinitions()
	return WidgetUtil.collect(
		{
			align = 'center',
			nowrap = true,
			shrink = true,
			sortType = 'isoDate',
		},
		{
			align = 'center',
			minWidth = '80px',
		},
		{
			align = 'left',
			minWidth = '4.5rem',
			nowrap = true,
			shrink = true,
		},
		self.config.showType and {
			align = 'center',
			minWidth = '50px',
		} or nil,
		self.config.displayGameIcons and {
			align = 'center'
		} or nil,
		{align = 'left'},
		{
			align = 'left',
			shrink = true,
			nowrap = true,
		},
		(self.config.queryType ~= Opponent.team or Table.isNotEmpty(self.config.aliases)) and {
			align = 'center',
			minWidth = '70px',
		} or self.config.playerResultsOfTeam and {
			align = 'center',
			minWidth = '105px',
		} or nil,
		not self.config.hideResult and {
			{
				align = 'center',
				sortable = false,
			},
			{
				align = 'center',
				sortable = false,
			},
		} or nil,
		{
			align = 'right',
			sortType = 'currency',
		}
	)
end

---Builds the Header of the results/achievements table
---@return Widget
function ResultsTable:buildHeader()
	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Date'},
		TableWidgets.CellHeader{children = 'Place'},
		TableWidgets.CellHeader{children = 'Tier'},
		self.config.showType and TableWidgets.CellHeader{children = 'Type'} or nil,
		self.config.displayGameIcons and TableWidgets.CellHeader{
			children = HtmlWidgets.Abbreviation{children = 'G.', title = 'Game'}
		} or nil,
		TableWidgets.CellHeader{
			colspan = 2,
			children = 'Tournament'
		},
		(self.config.queryType ~= Opponent.team or Table.isNotEmpty(self.config.aliases)) and TableWidgets.CellHeader{
			children = 'Team'
		} or self.config.playerResultsOfTeam and TableWidgets.CellHeader{
			children = 'Player'
		} or nil,
		not self.config.hideResult and TableWidgets.CellHeader{
			colspan = 2,
			children = 'Result'
		} or nil,
		TableWidgets.CellHeader{children = 'Prize'}
	)}
end

---Builds a placement row of the results/achievements table
---@param placement placement
---@return Html
function ResultsTable:buildRow(placement)
	return TableWidgets.Row{
		highlighted = self:rowHighlight(placement),
		children = WidgetUtil.collect(
			self:createDateCell(placement),
			ResultsTable._placementToTableCell(placement),
			self:createTierCell(placement),
			self:createTypeCell(placement),
			self.config.displayGameIcons and TableWidgets.Cell{
				children = Game.icon{game = placement.game}
			} or nil,
			self:createTournamentCells(placement),
			(
				self.config.playerResultsOfTeam or
				self.config.queryType ~= Opponent.team or
				Table.isNotEmpty(self.config.aliases)
			) and TableWidgets.Cell{
				align = self.config.hideResult and 'left' or 'right',
				attributes = {
					['data-sort-value'] = placement.opponentname
				},
				children = self:opponentDisplay(
					placement,
					{teamForSolo = not self.config.playerResultsOfTeam, flip = not self.config.hideResult}
				)
			} or nil,
			self:_buildResultCells(placement),
			self:createPrizeCell{
				useIndivPrize = self.config.useIndivPrize and self.config.queryType ~= Opponent.team,
				placement = placement
			}
		)
	}
end

---@private
---@param placement placement
---@return Widget
ResultsTable._placementToTableCell = FnUtil.memoize(function (placement)
	local rawPlacement = Placement.raw(placement.placement or '')
	return TableWidgets.Cell{
		attributes = {
			['data-sort-value'] = rawPlacement.sort
		},
		classes = {rawPlacement.backgroundClass},
		children = HtmlWidgets.B{
			classes = not rawPlacement.blackText and {'placement-text'} or nil,
			children = rawPlacement.display
		}
	}
end)

---@private
---@param placement placement
---@return Widget[]?
function ResultsTable:_buildResultCells(placement)
	if self.config.hideResult then
		return
	end
	local score, vsDisplay, groupAbbr = self:processVsData(placement)
	return {
		TableWidgets.Cell{children = score},
		TableWidgets.Cell{
			align = 'left',
			css = {padding = groupAbbr and '14px' or nil},
			children = vsDisplay or groupAbbr
		}
	}
end

return ResultsTable
