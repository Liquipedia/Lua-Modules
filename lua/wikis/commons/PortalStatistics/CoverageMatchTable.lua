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
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Count = Lua.import('Module:Count')

local LANG = mw.getContentLanguage()
local GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value.name
end)

local StatisticsPortal = {}


---@param args table?
---@return Renderable
function StatisticsPortal.coverageMatchTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES)

	local tableHeader = TableWidgets.Row{
		children = WidgetUtil.collect(
			args.multiGame and TableWidgets.CellHeader{children = 'Game'} or nil,
			TableWidgets.CellHeader{children = args.matchesTitle or 'Matches'},
			TableWidgets.CellHeader{children = args.gamesTitle or 'Games'}
		)
	}

	local tableRow = WidgetUtil.collect(
		args.multiGame and Array.map(args.customGames, function(game)
			return StatisticsPortal._coverageMatchTableRow(args, {game = game, year = args.year})
		end) or nil,
		StatisticsPortal._coverageMatchTableRow(args, {year = args.year})
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
function StatisticsPortal._coverageMatchTableRow(args, parameters)
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
			Logic.readBool(args.multiGame) and StatisticsPortal._returnGameCell(args, parameters, isHeaderRow) or nil,
			CellComponent{align = 'right', children = LANG:formatNum(matchCountValue)},
			CellComponent{align = 'right', children = LANG:formatNum(gameCountValue)}
		)
	}
end

---@param args table
---@param parameters table
---@param isHeaderRow boolean
---@return Renderable
function StatisticsPortal._returnGameCell(args, parameters, isHeaderRow)
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell
	local text = (Logic.readBool(args.multiGame) and not parameters.game) and 'Total' or parameters.game
	return CellComponent{children = text}
end

---@param input string|table|nil
---@param default table?
---@return table
function StatisticsPortal._isTableOrSplitOrDefault(input, default)
	if type(input) == 'table' then
		return input
	elseif String.isEmpty(input) then
		return default or {}
	end
	return Array.parseCommaSeparatedString(input)
end

return Class.export(StatisticsPortal, {exports = {'coverageMatchTable'}})
