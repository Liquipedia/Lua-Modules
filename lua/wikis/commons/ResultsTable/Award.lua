---
-- @Liquipedia
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BaseResultsTable = Lua.import('Module:ResultsTable/Base')
local Class = Lua.import('Module:Class')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local ReferenceTag = Lua.import('Module:Widget/ReferenceTag')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AwardsTable: BaseResultsTable
---@operator call(table): AwardsTable
local AwardsTable = Class.new(BaseResultsTable)

---@protected
---@return Table2ColumnDef[]
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
		(self.config.queryType ~= Opponent.team or self.config.playerResultsOfTeam) and {
			align = 'left',
		} or nil,
		{
			align = 'right',
			sortType = 'currency',
		}
	)
end

---Builds the Header of the award table
---@return VNode
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

---@private
---@param placement placement
---@return Renderable|Renderable[]
function AwardsTable._createAwardCell(placement)
	local award = placement.extradata.award
	local references = placement.extradata.references
	if not references then
		return award
	end
	local frame = mw.getCurrentFrame()
	return Array.extend(
		award,
		Array.map(references, function (reference)
			return ReferenceTag{
				frame = frame,
				name = Table.extract(reference, 'name'),
				children = Template.safeExpand(frame, 'Cite web', reference)
			}
		end)
	)
end

---Builds a row of the award table
---@param placement placement
---@return VNode
function AwardsTable:buildRow(placement)
	return TableWidgets.Row{
		highlighted = self:rowHighlight(placement),
		children = WidgetUtil.collect(
			self:createDateCell(placement),
			self:createTierCell(placement),
			self:createTypeCell(placement),
			self:createTournamentCells(placement),
			TableWidgets.Cell{children = AwardsTable._createAwardCell(placement)},
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
