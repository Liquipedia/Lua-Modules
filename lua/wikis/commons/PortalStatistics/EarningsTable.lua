---
-- @Liquipedia
-- page=Module:PortalStatistics/EarningsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local Flags = Lua.import('Module:Flags')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Lpdb = Lua.import('Module:Lpdb')
local Medals = Lua.import('Module:Medals')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local CURRENCY_FORMAT_OPTIONS = {dashIfZero = true, displayCurrencyCode = false, formatValue = true}
local DEFAULT_ALLOWED_PLACES = {'1', '2', '3', '1-2', '1-3', '2-3', '2-4', '3-4'}
local US_DOLLAR = 'USD'
local SHOWMATCH = 'Showmatch'
local TIER1 = '1'
local FIRST = '1'
local MINIMUM_EARNINGS = 1000

local StatisticsPortal = {}


---@param args table?
---@return Renderable
function StatisticsPortal.earningsTable(args)
	args = args or {}
	args.limit = tonumber(args.limit) or 20
	args.opponentType = args.opponentType or Opponent.team
	args.displayShowMatches = Logic.readBool(args.displayShowMatches)
	args.allowedPlacements = StatisticsPortal._isTableOrSplitOrDefault(
		args.allowedPlacements,
		DEFAULT_ALLOWED_PLACES
	)
	args.minimumEarnings = tonumber(args.minimumEarnings) or MINIMUM_EARNINGS

	local earningsFunction = function (a)
		if String.isNotEmpty(args.year) then
			return a.earningsbyyear[tonumber(args.year)] or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	local opponentData

	if args.opponentType == Opponent.team then
		opponentData = StatisticsPortal._getTeams()
	elseif args.opponentType == Opponent.solo then
		opponentData = StatisticsPortal._getPlayers(
			nil,
			ConditionUtil.anyOf(
				ColumnName('nationality'),
				Array.map(Array.parseCommaSeparatedString(args.nationality), function (nationality)
					return Flags.CountryName{flag = nationality}
				end)
			)
		)
	end

	table.sort(opponentData, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	local opponentPlacements = StatisticsPortal._cacheOpponentPlacementData(args)

	local tableRow = {}
	for opponentIndex, opponent in ipairs(opponentData) do
		local earnings = earningsFunction(opponent)

		if opponentIndex > args.limit or earnings < args.minimumEarnings then break end

		local opponentDisplay
		if args.opponentType == Opponent.team then
			opponentDisplay = OpponentDisplay.BlockOpponent{
				opponent = Opponent.readOpponentArgs{template = opponent.template, type = Opponent.team},
				teamStyle = 'standard',
			}
		else
			opponentDisplay = OpponentDisplay.BlockOpponent{
				opponent = StatisticsPortal._toOpponent(opponent),
			}
		end
		local placements = opponentPlacements[opponent.pagename] or {}
		table.insert(tableRow,
			StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay))
	end

	return TableWidgets.Table{
		sortable = true,
		css = {['margin-left'] = '0px', ['margin-right'] = 'auto', width = '100%'},
		children = {
			TableWidgets.TableHeader{children = StatisticsPortal._earningsTableHeader(args)},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end


--[[
Section: Player Age Table Breakdown
]]--

---@param tableName string Name of the table
---@param parameters table Query parameters
---@return table
function StatisticsPortal._massQuery(tableName, parameters)
	local data = {}

	Lpdb.executeMassQuery(tableName, parameters, function (item)
		table.insert(data, item)
	end, parameters.limit)

	return data
end

---@param limit number?
---@param addConditions string|AbstractConditionNode?
---@param addOrder string?
---@return table
function StatisticsPortal._getPlayers(limit, addConditions, addOrder)
	return StatisticsPortal._massQuery('player', {
		query = 'pagename, id, nationality, earnings, birthdate, team, earningsbyyear',
		conditions = addConditions and tostring(addConditions) or '',
		order = addOrder,
		limit = limit,
	})
end

---@param limit number?
---@param addConditions string?
---@param addOrder string?
---@return table
function StatisticsPortal._getTeams(limit, addConditions, addOrder)
	return StatisticsPortal._massQuery('team', {
		query = 'pagename, name, template, earnings, earningsbyyear',
		conditions = addConditions or '',
		order = addOrder,
		limit = limit,
	})
end

---@param args table
---@return table
function StatisticsPortal._cacheOpponentPlacementData(args)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier')}
		:add{ConditionNode(ColumnName('prizemoney'), Comparator.gt, 0)}

	if String.isNotEmpty(args.year) then
		conditions:add{
			ConditionNode(ColumnName('date_year'), Comparator.eq, args.year)
		}
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, allowedPlacement in pairs(args.allowedPlacements) do
		placementConditions:add{ConditionNode(ColumnName('placement'), Comparator.eq, allowedPlacement)}
	end

	conditions:add{placementConditions}
	local data = {}

	local queryParameters = {
		query = 'pagename, shortname, icon, icondark, '
			.. 'liquipediatier, liquipediatiertype, placement, '
			.. 'opponentplayers, opponentname, opponenttype',
		conditions = conditions:toString(),
		limit = 1000,
		order = 'date asc',
	}

	local function makeOpponentTable(item)
		local opponentNames = {}
		if args.opponentType == Opponent.solo then
			for _, playerName in Table.iter.pairsByPrefix(item.opponentplayers or {}, 'p') do
				local name = string.gsub(playerName or '', ' ', '_')
				table.insert(opponentNames, name)
			end
		elseif args.opponentType == Opponent.team and item.opponenttype == Opponent.team then
			local name = string.gsub(item.opponentname or '', ' ', '_')
			table.insert(opponentNames, name)
		end
		return opponentNames
	end

	local processData = function(item)
		local placement = string.sub(item.placement, 1, 1)
		for _, opponent in pairs(makeOpponentTable(item) or {}) do
			if not data[opponent] then
				data[opponent] = {['1'] = 0, ['2'] = 0, ['3'] = 0, showWins = 0, sWinData = {}}
			end
			if placement == FIRST and item.liquipediatier == TIER1 and item.liquipediatiertype ~= SHOWMATCH then
				table.insert(data[opponent].sWinData, {
						icon = item.icon,
						iconDark = item.icondark,
						pagename = item.pagename,
						shortname = item.shortname
					}
				)
			end
			if placement == FIRST and item.liquipediatiertype == SHOWMATCH then
				data[opponent].showWins = data[opponent].showWins + 1
			elseif item.liquipediatiertype ~= SHOWMATCH then
				data[opponent][placement] = data[opponent][placement] + 1
			end
		end
	end

	Lpdb.executeMassQuery('placement', queryParameters, processData)

	return data
end


--[[
Section: Display Functions
]]--

---@param args table
---@return Renderable
function StatisticsPortal._earningsTableHeader(args)
	local columnText = args.opponentType == Opponent.team and 'Organization' or 'Player'

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{unsortable = true, children = '#'},
			TableWidgets.CellHeader{unsortable = true, children = columnText},
			TableWidgets.CellHeader{unsortable = true, children = 'Achievements'},
			TableWidgets.CellHeader{children = Medals.display{medal = 1}},
			TableWidgets.CellHeader{children = Medals.display{medal = 2}},
			TableWidgets.CellHeader{children = Medals.display{medal = 3}},
			Logic.readBool(args.displayShowMatches) and TableWidgets.CellHeader{children = 'Show<br>Match'} or nil,
			TableWidgets.CellHeader{
				children = Html.Abbr{title = 'Total earnings across all games', children = 'Earnings'}
			}
		)
	}
end

---@param args table
---@param placements table
---@param earnings number
---@param opponentIndex number
---@param opponentDisplay Renderable
---@return Renderable
function StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay)
	return TableWidgets.Row{
		css = {['line-height'] = '25px', ['text-align'] = 'center'},
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = opponentIndex},
			TableWidgets.Cell{align = 'left', children = opponentDisplay},
			TableWidgets.Cell{nowrap = false, children = StatisticsPortal._achievementsDisplay(placements.sWinData or {})},
			TableWidgets.Cell{children = placements['1'] or '0'},
			TableWidgets.Cell{children = placements['2'] or '0'},
			TableWidgets.Cell{children = placements['3'] or '0'},
			Logic.readBool(args.displayShowMatches) and TableWidgets.Cell{children = placements.showWins or 0} or nil,
			TableWidgets.Cell{align = 'right', children = Currency.display(US_DOLLAR, earnings, CURRENCY_FORMAT_OPTIONS)}
		)
	}
end

---@param data table
---@return string
function StatisticsPortal._achievementsDisplay(data)
	local output = ''
	if data and type(data[1]) == 'table' then
		for _, item in ipairs(data) do
			item.icon = string.gsub(item.icon or '', 'File:', '')
			item.iconDark = string.gsub(item.iconDark or '', 'File:', '')
			item.icon = Logic.emptyOr(item.icon, 'Gold.png')
			output = output .. LeagueIcon.display{
				icon = item.icon,
				iconDark = item.iconDark,
				link = item.pagename,
				name = item.shortname,
				options = { noTemplate = true },
			}
			output = output .. ' '
		end
	end
	return output
end

---@param player table
---@return table
function StatisticsPortal._toOpponent(player)
	return {
		type = Opponent.solo,
		players = {{
			pageName = player.pagename,
			displayName = player.id,
			flag = player.nationality,
			team = String.isNotEmpty(player.team) and player.team or nil,
		}},
	}
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

return Class.export(StatisticsPortal, {exports = {'earningsTable'}})
