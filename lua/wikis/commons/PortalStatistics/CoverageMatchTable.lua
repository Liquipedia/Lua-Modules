---
-- @Liquipedia
-- page=Module:PortalStatistics/CoverageMatchTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Util = Lua.import('Module:PortalStatistics/Util')

local Count = Lua.import('Module:Count')

local LANG = mw.getContentLanguage()

local CoverageMatchTable = {}


---@param args table?
---@return Renderable
function CoverageMatchTable.coverageMatchTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = Util.isTableOrSplitOrDefault(args.customGames, Util.GAMES)

	local tableHeader = TableWidgets.Row{
		children = WidgetUtil.collect(
			args.multiGame and TableWidgets.CellHeader{children = 'Game'} or nil,
			TableWidgets.CellHeader{children = args.matchesTitle or 'Matches'},
			TableWidgets.CellHeader{children = args.gamesTitle or 'Games'}
		)
	}

	local tableRow = WidgetUtil.collect(
		args.multiGame and Array.map(args.customGames, function(game)
			return CoverageMatchTable._coverageMatchTableRow(args, {game = game, year = args.year})
		end) or nil,
		CoverageMatchTable._coverageMatchTableRow(args, {year = args.year})
	)

	return TableWidgets.Table{
		caption = args.matchTableTitle or (args.alignSide and Html.Br{} or ''),
		children = {
			TableWidgets.TableHeader{children = tableHeader},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end

---@param args table
---@param parameters table
---@return Renderable
function CoverageMatchTable._coverageMatchTableRow(args, parameters)
	local isHeaderRow = Logic.readBool(args.multiGame) and not parameters.game
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell

	local matchCountValue
	local gameCountValue

	if Info.config.match2.status == 0 then
		---@diagnostic disable-next-line: deprecated
		matchCountValue = Count.matches(parameters)
		---@diagnostic disable-next-line: deprecated
		gameCountValue = Count.games(parameters)
	else
		matchCountValue = Count.match2(parameters)
		gameCountValue = Count.match2game(parameters)
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			Logic.readBool(args.multiGame) and Util.returnGameCell(args, parameters, isHeaderRow) or nil,
			CellComponent{align = 'right', children = LANG:formatNum(matchCountValue)},
			CellComponent{align = 'right', children = LANG:formatNum(gameCountValue)}
		)
	}
end

return Class.export(CoverageMatchTable, {exports = {'coverageMatchTable'}})
