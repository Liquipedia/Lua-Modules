---
-- @Liquipedia
-- page=Module:ResultsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Page = Lua.import('Module:Page')
local Placement = Lua.import('Module:Placement')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')

local Opponent = Lua.import('Module:Opponent/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

---@class ResultsTable: BaseResultsTable
---@operator call(table): ResultsTable
local ResultsTable = Class.new(BaseResultsTable)

---@return Table2ColumnDef[]
function ResultsTable:getColumns()
	local config = self.config

	return WidgetUtil.collect(
		{width = '100px'},
		{minWidth = '80px'},
		{minWidth = '75px'},
		config.showType and {minWidth = '50px'} or nil,
		config.displayGameIcons and {minWidth = '50px'} or nil,
		{width = '30px'},
		{minWidth = '390px', align = 'left'},
		(config.playerResultsOfTeam or config.queryType ~= Opponent.team or Table.isNotEmpty(config.aliases))
			and {minWidth = '70px', align = 'right'} or nil,
		not config.hideResult and {minWidth = '52px'} or nil,
		not config.hideResult and {minWidth = '52px', align = 'left'} or nil,
		{sortType = 'currency'}
	)
end

---@return Widget
function ResultsTable:buildHeader()
	local config = self.config

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Date', width = '100px'},
			TableWidgets.CellHeader{children = 'Place', minWidth = '80px'},
			TableWidgets.CellHeader{children = 'Tier', minWidth = '75px'},
			config.showType and TableWidgets.CellHeader{children = 'Type', minWidth = '50px'} or nil,
			config.displayGameIcons and TableWidgets.CellHeader{
				children = Abbreviation.make{text = 'G.', title = 'Game'},
				minWidth = '50px'
			} or nil,
			TableWidgets.CellHeader{colspan = 2, children = 'Tournament', width = '420px'},
			(config.playerResultsOfTeam or config.queryType ~= Opponent.team or Table.isNotEmpty(config.aliases))
				and TableWidgets.CellHeader{
					children = config.playerResultsOfTeam and 'Player' or 'Team',
					minWidth = '70px'
				} or nil,
			not config.hideResult and TableWidgets.CellHeader{
				colspan = 2,
				children = 'Result',
				minWidth = '105px',
				unsortable = true
			} or nil,
			TableWidgets.CellHeader{children = 'Prize', sortType = 'currency'}
		)}
	}}
end

---@param placement table
---@return Widget
function ResultsTable:buildRow(placement)
	local config = self.config

	local placementData = Placement.raw(placement.placement)
	local tierDisplay, tierSortValue = self:tierDisplay(placement)
	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)

	local cells = WidgetUtil.collect(
		TableWidgets.Cell{children = DateExt.toYmdInUtc(placement.date)},
		TableWidgets.Cell{
			children = placementData.display,
			attributes = {['data-sort-value'] = placementData.sort},
			classes = placementData.blackText
				and {placementData.backgroundClass}
				or {placementData.backgroundClass, 'placement-text'}
		},
		TableWidgets.Cell{
			children = tierDisplay,
			attributes = {['data-sort-value'] = tierSortValue}
		},
		config.showType and TableWidgets.Cell{children = placement.type} or nil,
		config.displayGameIcons and TableWidgets.Cell{children = Game.icon{game = placement.game}} or nil,
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
		(config.playerResultsOfTeam or config.queryType ~= Opponent.team or Table.isNotEmpty(config.aliases))
			and TableWidgets.Cell{
				children = self:opponentDisplay(placement, {
					teamForSolo = not config.playerResultsOfTeam,
					flip = not config.hideResult
				}),
				attributes = {['data-sort-value'] = placement.opponentname}
			} or nil
	)

	if not config.hideResult then
		local score, vsDisplay, groupAbbr = self:processVsData(placement)
		Array.extendWith(cells, {
			TableWidgets.Cell{children = score},
			TableWidgets.Cell{
				children = vsDisplay or groupAbbr,
				css = groupAbbr and {['padding-left'] = '14px'} or nil
			}
		})
	end

	local useIndivPrize = config.useIndivPrize and config.queryType ~= Opponent.team
	Array.appendWith(cells, TableWidgets.Cell{children = Currency.display('USD',
		useIndivPrize and placement.individualprizemoney or placement.prizemoney,
		{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
	)})

	return TableWidgets.Row{
		highlighted = HighlightConditions.tournament(placement, config),
		children = cells
	}
end

return ResultsTable
