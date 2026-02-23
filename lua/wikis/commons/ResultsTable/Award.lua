---
-- @Liquipedia
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Page = Lua.import('Module:Page')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Opponent = Lua.import('Module:Opponent/Custom')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

---@class AwardsTable: BaseResultsTable
---@operator call(table): AwardsTable
local AwardsTable = Class.new(BaseResultsTable)

---@return Table2ColumnDef[]
function AwardsTable:getColumns()
	local config = self.config

	return WidgetUtil.collect(
		{width = '100px'},
		{minWidth = '75px'},
		config.showType and {minWidth = '50px'} or nil,
		{width = '30px'},
		{minWidth = '245px', align = 'left'},
		{minWidth = '225px', align = 'left'},
		(config.playerResultsOfTeam or config.queryType ~= Opponent.team)
			and {minWidth = '70px', align = 'left'} or nil,
		{sortType = 'currency'}
	)
end

---@return Widget
function AwardsTable:buildHeader()
	local config = self.config

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Date', width = '100px'},
			TableWidgets.CellHeader{children = 'Tier', minWidth = '75px'},
			config.showType and TableWidgets.CellHeader{children = 'Type', minWidth = '50px'} or nil,
			TableWidgets.CellHeader{colspan = 2, children = 'Tournament', width = '275px'},
			TableWidgets.CellHeader{children = 'Award', minWidth = '225px'},
			(config.playerResultsOfTeam or config.queryType ~= Opponent.team)
				and TableWidgets.CellHeader{
					children = config.playerResultsOfTeam and 'Player' or 'Team',
					minWidth = '70px'
				} or nil,
			TableWidgets.CellHeader{children = 'Prize', sortType = 'currency'}
		)}
	}}
end

---@param placement table
---@return Widget
function AwardsTable:buildRow(placement)
	local config = self.config

	local tierDisplay, tierSortValue = self:tierDisplay(placement)
	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)

	return TableWidgets.Row{
		highlighted = HighlightConditions.tournament(placement, config),
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = DateExt.toYmdInUtc(placement.date)},
			TableWidgets.Cell{
				children = tierDisplay,
				attributes = {['data-sort-value'] = tierSortValue}
			},
			config.showType and TableWidgets.Cell{children = placement.type} or nil,
			TableWidgets.Cell{
				children = LeagueIcon.display{
					icon = placement.icon,
					iconDark = placement.icondark,
					link = placement.parent,
					name = tournamentDisplayName,
					options = {noTemplate = true},
				},
				attributes = {['data-sort-value'] = tournamentDisplayName}
			},
			TableWidgets.Cell{
				children = Page.makeInternalLink({}, tournamentDisplayName, placement.pagename),
				attributes = {['data-sort-value'] = tournamentDisplayName}
			},
			TableWidgets.Cell{children = placement.extradata.award},
			(config.playerResultsOfTeam or config.queryType ~= Opponent.team)
				and TableWidgets.Cell{
					children = self:opponentDisplay(placement, {
						teamForSolo = not config.playerResultsOfTeam
					}),
					attributes = {['data-sort-value'] = placement.opponentname}
				} or nil,
			TableWidgets.Cell{children = Currency.display('USD',
				config.queryType ~= Opponent.team and placement.individualprizemoney or placement.prizemoney,
				{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
			)}
		)
	}
end

return AwardsTable
