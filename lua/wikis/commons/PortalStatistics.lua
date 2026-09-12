---
-- @Liquipedia
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Game = Lua.import('Module:Game')
local Info = Lua.import('Module:Info', {loadData = true})
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Lpdb = Lua.import('Module:Lpdb')
local Math = Lua.import('Module:MathUtil')
local Medals = Lua.import('Module:Medals')
local Operator = Lua.import('Module:Operator')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Box = Lua.import('Module:Widget/Basic/Box')
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

local Count = Lua.import('Module:Count')

local CURRENCY_FORMAT_OPTIONS = {dashIfZero = true, displayCurrencyCode = false, formatValue = true}
local TIMESTAMP = DateExt.getCurrentTimestamp()
local CURRENT_YEAR = DateExt.getYearOf()
local DATE = DateExt.toYmdInUtc(TIMESTAMP)
local DEFAULT_ALLOWED_PLACES = {'1', '2', '3', '1-2', '1-3', '2-3', '2-4', '3-4'}
local DEFAULT_ROUND_PRECISION = Info.defaultRoundPrecision or 2
local LANG = mw.getContentLanguage()
local MAX_OPPONENT_LIMIT = Info.config.defaultMaxPlayersPerPlacement or 10
local MAX_QUERY_LIMIT = 5000
local US_DOLLAR = 'USD'
local SHOWMATCH = 'Showmatch'
local TIER1 = '1'
local FIRST = '1'
local MODES = {'solo', 'team', 'other'}
local TYPES = {'Online', 'Offline'}
local GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value.name
end)
local DEFAULT_TIERTYPES = {'', 'Weekly', 'Monthly'}
local MINIMUM_EARNINGS = 1000


local StatisticsPortal = {}

--[[
Section: Chart Entry Functions
]] --


---@param args table?
---@return Renderable
function StatisticsPortal.gameEarningsChart(args)
	args = args or {}

	local games = Array.map(StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES), function(game)
		return Game.toIdentifier{game = game, useDefault = false} or game
	end)

	local params = {
		variable = 'game',
		processFunction = StatisticsPortal._defaultProcessFunction,
		catLabel = 'Year',
		defaultInputs = games,
		axisRotate = tonumber(args.axisRotate),
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local yearSeriesData = StatisticsPortal._cacheModeEarningsData(config)
	return StatisticsPortal._buildChartData(config, yearSeriesData, config.customLegend, true)
end


---@param args table?
---@return Renderable
function StatisticsPortal.modeEarningsChart(args)
	args = args or {}

	local params = {
		variable = 'opponenttype',
		processFunction = StatisticsPortal._defaultProcessFunction,
		catLabel = 'Year',
		defaultInputs = MODES,
		axisRotate = tonumber(args.axisRotate),
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local yearSeriesData = StatisticsPortal._cacheModeEarningsData(config)
	return StatisticsPortal._buildChartData(config, yearSeriesData, config.customLegend, true)
end


---@param args table?
---@return Renderable
function StatisticsPortal.topEarningsChart(args)
	args = args or {}
	args.limit = tonumber(args.limit) or 10
	args.startYear = tonumber(args.year)

	local params = {
		catLabel = Logic.readBool(args.isForTeam) and 'Teams' or 'Players',
		flipAxes = true,
		emphasis = 'none',
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local topEarningsList = StatisticsPortal._getOpponentEarningsData(args, config)

	local yearSeriesData = Array.mapRange(config.startYear, tonumber(args.year) or CURRENT_YEAR, function(year)
		return Array.map(Array.reverse(topEarningsList), function(teamData)
			return teamData.earningsbyyear[year] or 0
		end)
	end)

	local opponentNames = Array.map(Array.reverse(topEarningsList), function(opponent)
		return config.opponentType == Opponent.team and opponent.name or opponent.id
	end)

	if Logic.readBool(config.yearBreakdown) then
		return StatisticsPortal._buildChartData(config, yearSeriesData, opponentNames)
	else
		local chartData = {}
		chartData[1] = {
			name = 'Total Earnings',
			type = 'bar',
			stack = config.stackType,
			data = StatisticsPortal._addArrays(yearSeriesData),
		}

		config.yAxis = {
			type = 'value',
			name = 'Earnings ($USD)',
		}
		config.xAxis = {
			type = 'category',
			name = config.catLabel,
			data = opponentNames,
			axisTick = {
				alignWithLabel = true,
			},
		}
		config.customLegend = config.customLegend or config.customInputs
		return StatisticsPortal._drawChart(config, chartData)
	end
end


--[[
Section: Coverage Breakdown
]] --


---@param args table?
---@return VNode
function StatisticsPortal.coverageStatistics(args)
	args = args or {}
	args.alignSide = Logic.readBool(args.alignSide)

	local statsChildren = {
		StatisticsPortal.coverageTournamentTable(args),
		StatisticsPortal.coverageMatchTable(args)
	}

	if args.alignSide then
		return Box{
			paddingRight = '2em',
			children = statsChildren,
		}
	else
		return Html.Div{
			children = statsChildren,
		}
	end
end


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
		matchCountValue = Count.match2game(parameters)
		gameCountValue = Count.match2(parameters)
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			Logic.readBool(args.multiGame) and StatisticsPortal._returnGameCell(args, parameters, isHeaderRow) or nil,
			CellComponent{align = 'right', children = LANG:formatNum(matchCountValue)},
			CellComponent{align = 'right', children = LANG:formatNum(gameCountValue)}
		)
	}
end


---@param args table?
---@return Renderable
function StatisticsPortal.coverageTournamentTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES)
	args.customTiers = StatisticsPortal._isTableOrSplitOrDefault(args.customTiers)
	args.customTiers = args.customTiers and Array.map(args.customTiers, function(tier) return tonumber(tier) end)
	args.includeTierTypes = StatisticsPortal._isTableOrSplitOrDefault(args.includeTierTypes, DEFAULT_TIERTYPES)
	args.showTierTypes = StatisticsPortal._isTableOrSplitOrDefault(args.showTierTypes, {})
	args.filterByStatus = Logic.readBool(args.filterByStatus) or false

	local tableRow = WidgetUtil.collect(
		args.multiGame and Array.map(args.customGames, function(game)
			return StatisticsPortal._coverageTournamentTableRow(args, {
				game = game,
				year = args.year,
				filterByStatus = args.filterByStatus
			})
		end) or nil,
		StatisticsPortal._coverageTournamentTableRow(args, {
			year = args.year,
			filterByStatus = args.filterByStatus
		})
	)

	return TableWidgets.Table{
		caption = args.tournamentTableTitle or 'Tournaments Covered',
		children = {
			TableWidgets.TableHeader{children = StatisticsPortal._coverageTournamentTableHeader(args)},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end


---@param args table
---@param parameters table
---@return Renderable
function StatisticsPortal._coverageTournamentTableRow(args, parameters)
	local isHeaderRow = Logic.readBool(args.multiGame) and not parameters.game
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell
	local runningTally = 0

	local gameCell = Logic.readBool(args.multiGame)
		and StatisticsPortal._returnGameCell(args, parameters, isHeaderRow)
		or nil

	local countData = Count.tournamentsByTier(parameters)

	local tierCells = {}
	for rowIndex, rowValue in Tier.iterate('tiers') do
		if String.isNotEmpty(rowValue.value) and tonumber(rowValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == rowIndex
			end) then
				local tierData = countData[rowValue.value] or {}
				local tournamentCount = 0
				Array.forEach(args.includeTierTypes,
					function(tiertype, _)
						local typeCount = tonumber(Table.extract(tierData, tiertype)) or 0
						tournamentCount = tournamentCount + typeCount
					end
				)
				runningTally = runningTally + tournamentCount
				table.insert(tierCells, CellComponent{align = 'right', children = LANG:formatNum(tournamentCount)})
			end
		end
	end

	local tierTypeCells = Array.map(args.showTierTypes, function(tierTypeValue)
		local _, tierTypeData = Tier.raw(nil, tierTypeValue)
		if tierTypeData then
			local count = Array.reduce(
				Array.map(Array.extractValues(countData), function(typeCounts)
					return Table.extract(typeCounts, tierTypeValue) or 0
				end),
				Operator.add, 0
			)
			runningTally = runningTally + count
				return CellComponent{align = 'right', children = LANG:formatNum(count)}
			end
		end)

	local otherCell
	if String.isNotEmpty(args.showOther) then
		local countOther = Array.reduce(
			Array.flatMap(Array.extractValues(countData), function(typeCounts)
				return Table.isNotEmpty(typeCounts) and Array.extractValues(typeCounts) or 0
			end
			), Operator.add, 0) --[[@as number]]
		runningTally = runningTally + countOther
		otherCell = CellComponent{align = 'right', children = LANG:formatNum(countOther)}
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			gameCell,
			tierCells,
			tierTypeCells,
			otherCell,
			CellComponent{align = 'right', children = LANG:formatNum(runningTally)}
		)
	}
end


---@param args table
---@return Renderable
function StatisticsPortal._coverageTournamentTableHeader(args)
	local tierHeaderCells = {}
	for headerIndex, headerValue in Tier.iterate('tiers') do
		if String.isNotEmpty(headerValue.value) and tonumber(headerValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == headerIndex
			end) then
				table.insert(tierHeaderCells, TableWidgets.CellHeader{
					children = Tier.displaySingle(headerValue, {link = true})
				})
			end
		end
	end

	local tierTypeHeaderCells = {}
	if #args.showTierTypes then
		for _, tierTypeValue in ipairs(args.showTierTypes) do
			local _, tierTypeData = Tier.raw(nil, tierTypeValue)
			if tierTypeData then
				table.insert(tierTypeHeaderCells, TableWidgets.CellHeader{
					children = Tier.displaySingle(tierTypeData, {link = true, short = true})
				})
			end
		end
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			Logic.readBool(args.multiGame) and TableWidgets.CellHeader{children = 'Game'} or nil,
			tierHeaderCells,
			tierTypeHeaderCells,
			String.isNotEmpty(args.showOther) and TableWidgets.CellHeader{
				children = Abbreviation.make{text = 'Other',
					title = 'Includes otherwise unlisted tournaments (e.g. with tiertypes, misc.)'}
			} or nil,
			TableWidgets.CellHeader{children = 'Total'}
		)
	}
end

--[[
Section: Prizepool Breakdown
]]--


---@param args table?
---@return Renderable
function StatisticsPortal.prizepoolBreakdown(args)
	args = args or {}
	args.showAverage = Logic.readBool(args.showAverage)
	args.startYear = tonumber(args.startYear) or Info.startYear

	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(args)
	local rowLimit = Math.round(((Logic.readBool(args.showAverage) and 1 or 0) + 1 + Table.size(yearTable)) / 2)

	local tables = {}
	local headerCells = {}
	local resultCells = {}

	local function finalizeTable()
		table.insert(tables, TableWidgets.Table{
			caption = 'Prize Money Awarded',
			children = {
				TableWidgets.TableHeader{children = TableWidgets.Row{children = headerCells}},
				TableWidgets.TableBody{children = TableWidgets.Row{children = resultCells}}
			}
		})
		headerCells = {}
		resultCells = {}
	end

	local prizepoolSum = 0
	local prevYear = args.startYear
	local colIndex = 1

	for _, yearValue in pairs(defaultYearTable) do
		local conditions = StatisticsPortal._returnBaseConditions()

		if args.game then
			local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
			conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
		end

		conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate_year'), Comparator.eq, yearValue)
			}
		}

		local data = mw.ext.LiquipediaDB.lpdb('tournament', {
				query = 'sum::prizepool',
				limit = MAX_QUERY_LIMIT,
				conditions = conditions:toString(),
				order = 'sortdate desc',
			}
		)

		prizepoolSum = prizepoolSum + (tonumber(data[1].sum_prizepool) or 0)

		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			table.insert(headerCells, TableWidgets.CellHeader{
				children = StatisticsPortal._returnCustomYearText(prevYear, yearValue)
			})
			table.insert(resultCells, TableWidgets.Cell{
				children = Currency.display(US_DOLLAR, prizepoolSum or 0, CURRENCY_FORMAT_OPTIONS)
			})
			prizepoolSum = 0
			prevYear = yearValue + 1
			colIndex = colIndex + 1
		end

		if colIndex > rowLimit and rowLimit > 8 then
			colIndex = 1
			finalizeTable()
		end
	end

	local conditions = StatisticsPortal._returnBaseConditions()

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)
		},
	}

	local totalData = mw.ext.LiquipediaDB.lpdb('tournament', {
			query = 'sum::prizepool',
			limit = MAX_QUERY_LIMIT,
			conditions = conditions:toString(),
			order = 'sortdate desc',
		}
	)
	local totalPrizePool = tonumber(totalData[1].sum_prizepool) or 0

	table.insert(headerCells, TableWidgets.CellHeader{children = 'Total'})
	table.insert(resultCells, TableWidgets.Cell{
		children = Html.B{children = Currency.display(US_DOLLAR, totalPrizePool, CURRENCY_FORMAT_OPTIONS)}
	})

	if Logic.readBool(args.showAverage) then
		table.insert(headerCells, TableWidgets.CellHeader{
			children = Html.Abbr{title = 'Average Prizepool per Tournament', children = 'AVG PPT'}
		})
		table.insert(resultCells, TableWidgets.Cell{
			children = Html.B{children = Currency.display(
				US_DOLLAR, totalPrizePool / (Count.tournaments() or 1), CURRENCY_FORMAT_OPTIONS
			)}
		})
	end

	finalizeTable()

	local wrapperChildren = {}
	for index, tableWidget in ipairs(tables) do
		if index > 1 then
			table.insert(wrapperChildren, Html.Br{})
		end
		table.insert(wrapperChildren, tableWidget)
	end

	return Html.Div{children = wrapperChildren}
end


---@param args table?
---@return VNode
function StatisticsPortal.pieChartBreakdown(args)
	args = args or {}
	args.height = args.height or 300
	args.width = args.width or 400
	args.hideKey = Logic.readBool(args.hideKey)
	args.detailedKey = Logic.readBool(args.detailedKey)
	args.multiGame = Logic.readBool(args.multiGame)
	args.multiMode = Logic.readBool(args.multiMode)

	local wrapperChildren = {
		Html.Div{
			classes = {'template-box'},
			css = {
				['padding-right'] = '5em',
				['font-size'] = '85%',
				['text-align'] = 'center',
			},
			children = {
				'Tournament Type',
				StatisticsPortal._getPieChartData(
					args, 'type', 'Mixed', TYPES
				),
			},
		},
	}

	if args.multiGame then
		local games = Array.map(StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES), function(game)
			return Game.toIdentifier{game = game, useDefault = false} or game
		end)
		table.insert(wrapperChildren, Html.Div{
			classes = {'template-box'},
			css = {
				['padding-right'] = '5em',
				['font-size'] = '85%',
				['text-align'] = 'center',
			},
			children = {
				'Game Breakdown',
				StatisticsPortal._getPieChartData(args, 'game', 'Other', games),
			},
		})
	end

	if args.multiMode then
		table.insert(wrapperChildren, Box{
			paddingRight = '5em',
			children = {
				'Mode Breakdown',
				StatisticsPortal._getPieChartData(
					args, 'mode', 'Other', StatisticsPortal._isTableOrSplitOrDefault(args.customModes, {'Team'})
				),
			},
		})
	end

	if args.hideKey then
		return Html.Div{children = wrapperChildren}
	end

	if args.detailedKey then
		table.insert(wrapperChildren, Box{
			children = StatisticsPortal.prizepoolBreakdown(args),
		})
		return Html.Div{children = wrapperChildren}
	end

	local conditions = StatisticsPortal._returnBaseConditions()

	if args.year then
		conditions:add{ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('sortdate_year'), Comparator.eq, args.year),
			},
		}
	else
		conditions:add{ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE),
			},
		}
	end

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'sum::prizepool',
		limit = MAX_QUERY_LIMIT,
		conditions = conditions:toString(),
		order = 'sortdate desc',
	})

	local summaryTable = TableWidgets.Table{
		children = {
			TableWidgets.TableHeader{children = TableWidgets.Row{
				children = TableWidgets.CellHeader{children = 'Total prize money awarded'}
			}},
			TableWidgets.TableBody{children = TableWidgets.Row{
				children = TableWidgets.Cell{
					attributes = {['data-sort-type'] = 'currency'},
					children = Html.B{children = Currency.display(
						US_DOLLAR, data[1].sum_prizepool or 0, CURRENCY_FORMAT_OPTIONS
					)}
				}
			}}
		}
	}

	table.insert(wrapperChildren, Box{
		paddingRight = '1em',
		children = summaryTable,
	})

	return Html.Div{children = wrapperChildren}
end

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


---@param args table?
---@return Renderable
function StatisticsPortal.playerAgeTable(args)
	args = args or {}
	args.earnings = tonumber(args.earnings) or 500
	args.limit = tonumber(args.limit) or 20
	args.order = 'birthdate ' .. (args.order or 'desc')

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate)}
		:add{ConditionNode(ColumnName('deathdate'), Comparator.eq, DateExt.defaultDate)}
		:add{ConditionNode(ColumnName('earnings'), Comparator.gt, args.earnings)}

	if Logic.readBool(args.isActive) then
		conditions:add{ConditionNode(ColumnName('status'), Comparator.eq, 'Active')}
	end

	if Logic.readBool(args.playersOnly) then
		local typeConditions = ConditionTree(BooleanOperator.any)
		typeConditions:add{
			ConditionNode(ColumnName('type'), Comparator.eq, 'player'),
			ConditionNode(ColumnName('type'), Comparator.eq, 'Player'),
		}
		conditions:add{typeConditions}
	end

	conditions:add(ConditionUtil.anyOf(
		ColumnName('nationality'),
		Array.map(Array.parseCommaSeparatedString(args.nationality), function (nationality)
			return Flags.CountryName{flag = nationality}
		end)
	))

	local playerData = StatisticsPortal._getPlayers(args.limit, conditions:toString(), args.order)

	local tableHeader = TableWidgets.Row{
		children = {
			TableWidgets.CellHeader{unsortable = true, children = 'ID'},
			TableWidgets.CellHeader{children = 'Age'}
		}
	}

	local tableRow = Array.map(playerData, function(player)
		local birthdate = DateExt.readTimestamp(player.birthdate) --[[@as integer]]
		local age = os.date('*t', os.difftime(TIMESTAMP, birthdate))
		local yearAge = age.year - 1970
		local dayAge = age.yday - 1

		return TableWidgets.Row{
			children = {
				TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{
					opponent = StatisticsPortal._toOpponent(player),
					showPlayerTeam = true,
				}},
				TableWidgets.Cell{children = yearAge .. ' years, ' .. dayAge .. ' days'}
			}
		}
	end)

	return TableWidgets.Table{
		sortable = true,
		css = {['margin-left'] = '0px', ['margin-right'] = 'auto'},
		children = {
			TableWidgets.TableHeader{children = tableHeader},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end


--[[
Section: Query Functions
]]--

---Executes a given LPDB query using Lpdb.executeMassQuery
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
---@param config table
---@return table
function StatisticsPortal._getOpponentEarningsData(args, config)
	local opponentType = config.opponentType == Opponent.team and 'team' or 'player'
	local queryFields
	if opponentType == Opponent.team then
		queryFields = 'pagename, name, template, earnings, earningsbyyear'
	else
		queryFields = 'pagename, id, nationality, earnings, birthdate, team, earningsbyyear'
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('earnings'), Comparator.gt, 0)}

	local data = {}

	local processData = function(item)
		table.insert(data, item)
	end

	local queryParameters = {
		conditions = conditions:toString(),
		limit = MAX_QUERY_LIMIT,
		query = queryFields,
	}

	Lpdb.executeMassQuery(opponentType, queryParameters, processData)

	local earningsFunction = function (a)
		if String.isNotEmpty(args.year) then
			return a.earningsbyyear[tonumber(args.year)] or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	table.sort(data, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	return Array.sub(data, 1, args.limit)
end


---@param args table
---@param groupBy string
---@param defaultValue string
---@param groupValues table
---@return Renderable
function StatisticsPortal._getPieChartData(args, groupBy, defaultValue, groupValues)
	table.insert(groupValues, defaultValue)
	defaultValue = string.lower(defaultValue or '')

	local prizes = {}
	for _, value in Table.iter.spairs(groupValues) do
		prizes[value:lower()] = {name = value, value = 0}
	end

	local LPDBConditions = StatisticsPortal._returnBaseConditions()
	LPDBConditions:add{ConditionNode(ColumnName('namespace'), Comparator.eq, 0)}

	if args.year then
		LPDBConditions:add{ConditionNode(ColumnName('sortdate_year'), Comparator.eq, args.year)}
	else
		LPDBConditions:add{ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)}
	end

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		LPDBConditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	local function parseTournament(data)
		local normValue = string.lower(data[groupBy] or '')
		if prizes[normValue] then
			prizes[normValue].value = prizes[normValue].value + data.prizepool
		else
			prizes[defaultValue].value = prizes[defaultValue].value + data.prizepool
		end
	end

	--Querying data
	local queryParameters = {
		conditions = LPDBConditions:toString(),
		query = 'prizepool, ' .. groupBy,
	}

	--Querying data
	Lpdb.executeMassQuery('tournament', queryParameters, parseTournament)

	Array.forEach(Array.extractValues(prizes), function(prize)
		prize.value = math.floor(prize.value + 0.5)
	end)

	if prizes[defaultValue].value == 0 then
		Table.extract(prizes, defaultValue)
	end

	local chartData = Array.map(Array.extractValues(groupValues), function(value)
		return prizes[value:lower()]
	end)

	if groupBy == 'game' and Logic.readBool(args.abbreviateGame) then
		chartData = Array.map(chartData, function(entry)
			entry.name = Game.abbreviation{game = entry.name, useDefault = false} or entry.name
			return entry
		end)
	elseif groupBy == 'game' then
		chartData = Array.map(chartData, function(entry)
			entry.name = Game.name{game = entry.name, useDefault = false} or entry.name
			return entry
		end)
	end

	return StatisticsPortal._drawPieChart(args, chartData)
end


---@param config table
---@return table
function StatisticsPortal._cacheModeEarningsData(config)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('prizemoney'), Comparator.gt, 0)}
		:add{ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate)}
		:add{ConditionNode(ColumnName('date'), Comparator.lt, DATE)}

	if String.isNotEmpty(config.startYear) then
		conditions:add{ConditionNode(ColumnName('date_year'), Comparator.gt, (config.startYear - 1))}
	end

	if String.isNotEmpty(config.opponentName) then
		local teamConditions = ConditionTree(BooleanOperator.any)
			:add{ConditionNode(ColumnName('opponentname'), Comparator.eq, config.opponentName)}
		local prefix = config.opponentType == Opponent.team and 'team' or ''
		for index = 1, config.maxOpponents do
			teamConditions:add{
				ConditionNode(ColumnName('opponentplayers_p' .. index .. prefix), Comparator.eq, config.opponentName)}
		end
		conditions:add{teamConditions}
	end

	local earningsData = Table.map(Array.range(config.startYear, CURRENT_YEAR), function(_, year)
		return year, Table.map(config.customInputs, function(_, mode)
			return mode, 0
		end)
	end)

	local processData = function(item)
		local year = DateExt.getYearOf(item.date)
		if String.isNotEmpty(item[config.variable]) then
			local arg = item[config.variable]
			if earningsData[year][arg] then
				earningsData[year][arg] = config.processFunction(earningsData[year][arg], item, config)
			end
		end
	end

	local queryParameters = {
		conditions = conditions:toString(),
		limit = MAX_QUERY_LIMIT,
		query = 'opponenttype, prizemoney, individualprizemoney, date, game',
	}

	Lpdb.executeMassQuery('placement', queryParameters, processData)

	return Array.map(Array.extractValues(earningsData, Table.iter.spairs), function(value)
		return Array.map(config.customInputs, function(key)
			return value[key]
		end)
	end)
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
---@param parameters table
---@param isHeaderRow boolean
---@return Renderable
function StatisticsPortal._returnGameCell(args, parameters, isHeaderRow)
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell
	local text = (Logic.readBool(args.multiGame) and not parameters.game) and 'Total' or parameters.game
	return CellComponent{children = text}
end


---@param args table
---@return Renderable
function StatisticsPortal._earningsTableHeader(args)
	local columnText = args.opponentType == Opponent.team and 'Organization' or 'Player'

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{unsortable = true, children = '#'},
			TableWidgets.CellHeader{unsortable = true, children = columnText},
			TableWidgets.CellHeader{unsortable = true, width = '200px', children = 'Achievements'},
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
			TableWidgets.Cell{children = StatisticsPortal._achievementsDisplay(placements.sWinData or {})},
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


---@param config table
---@param chartData table
---@return Renderable
function StatisticsPortal._drawChart(config, chartData)
	return Html.Div{
		class = 'table-responsive',
		children = mw.ext.Charts.chart({
			grid = {
				left = '15%',
				right = '12%',
				top = '15%',
				bottom = '10%'
			},
			size = {
				height = config.height,
				width = config.width,
			},
			tooltip = {
				trigger = 'axis',
			},
			legend = config.customLegend,
			yAxis = config.flipAxes and config.xAxis or config.yAxis,
			xAxis = config.flipAxes and config.yAxis or config.xAxis,
			series = chartData,
			labels = config.labels,
		})
	}
end


---@param args table
---@param chartData table
---@return Renderable
function StatisticsPortal._drawPieChart(args, chartData)
	return Html.Div{
		class = 'table-responsive',
		children = mw.ext.Charts.piechart{
			size = {
				height = args.height,
				width = args.width
			},
			data = chartData
		}
	}
end


--[[
Section: Utility Functions
]]--


---@return ConditionTree
function StatisticsPortal._returnBaseConditions()
	return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'delayed')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '0')}
end


---@param config table
---@param yearSeriesData table
---@param nonYearCategories table
---@param transpose boolean?
---@return Renderable
function StatisticsPortal._buildChartData(config, yearSeriesData, nonYearCategories, transpose)
	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(config)
	local prevYear = config.startYear

	local yearList = {}
	local chartData = {}
	local seriesData = {}
	local earningsTable = Array.mapRange(1, Table.size(nonYearCategories), function() return 0 end)

	for yearIndex, yearValue in pairs(defaultYearTable) do
		earningsTable = StatisticsPortal._addArrays({earningsTable, yearSeriesData[yearIndex]})
		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			local yearText = StatisticsPortal._returnCustomYearText(prevYear, yearValue)
			table.insert(yearList, yearText)
			table.insert(seriesData, earningsTable)
			prevYear = yearValue + 1
			earningsTable = Array.mapRange(1, Table.size(nonYearCategories), function() return 0 end)
		end
	end

	local categoryNames = nonYearCategories
	local seriesNames = yearList

	if transpose == true then
		seriesData = Array.mapRange(1, Table.size(nonYearCategories), function(index)
			return Array.map(seriesData, function(teamData)
				return teamData[index] or 0
			end)
		end)
		seriesNames, categoryNames = categoryNames, seriesNames
	end

	if config.removeEmptyCategories == true then
		categoryNames, seriesData = StatisticsPortal._removeCategories(categoryNames, seriesData)
	end

	for seriesIndex, series in pairs(seriesNames) do
		if config.removeEmptySeries == true and Array.all(seriesData[seriesIndex], function(value)
			return value == 0
		end) then
			mw.logObject(series .. ' is empty')
		else
			table.insert(chartData, {
					name = series,
					type = config.chartType,
					stack = config.stackType,
					data = seriesData[seriesIndex],
					emphasis = {focus = config.emphasis},
				}
			)
		end
	end

	config.yAxis = {
		type = 'value',
		name = 'Earnings ($USD)'
	}
	config.xAxis = {
		type = 'category',
		name = config.catLabel,
		data = categoryNames,
		axisTick = {
			alignWithLabel = true,
		},
		axisLabel = {
			rotate = config.axisRotate,
		},
	}
	if Table.isEmpty(config.customLegend) then
		config.customLegend = seriesNames
	end

	return StatisticsPortal._drawChart(config, chartData)
end


---@param categoryNames table
---@param seriesData table
---@return table, table
function StatisticsPortal._removeCategories(categoryNames, seriesData)
	local startsEmpty = true
	local lastNotEmpty = 1

	local isEmptyCategory = Array.map(Array.map(categoryNames, function(_, catIndex)
		local truthValue = Array.all(Array.map(seriesData, function(_, index)
			return seriesData[index][catIndex] end), function(value)
				return value == 0
			end)
			if not truthValue then
				lastNotEmpty = catIndex
			end
			return truthValue
		end),
	function(value, index)
		if index > lastNotEmpty then
			return false
		elseif startsEmpty and value == true then
			return false
		else
			startsEmpty = false
			return true
		end
	end)

	categoryNames = Array.filter(categoryNames, function(_, catIndex)
		return Logic.readBool(isEmptyCategory[catIndex]) end)

	seriesData = Array.map(seriesData, function(_, index)
		return Array.filter(seriesData[index], function(_, catIndex)
			return Logic.readBool(isEmptyCategory[catIndex])
		end)
	end)
	return categoryNames, seriesData
end


---@param args table
---@param params table
---@return table
function StatisticsPortal._getChartConfig(args, params)
	local isForTeam = String.isNotEmpty(args.team) or Logic.readBool(args.isForTeam)
	local customInputs = StatisticsPortal._isTableOrSplitOrDefault(args.customInputs, params.defaultInputs)
	local opponentName
	if isForTeam then
		opponentName = args.team
	else
		opponentName = args.player
	end

	return {
		processFunction = params.processFunction,
		variable = params.variable,
		catLabel = params.catLabel,
		flipAxes = params.flipAxes or false,
		axisRotate = params.axisRotate or 0,
		emphasis = params.emphasis or 'series',
		customInputs = customInputs,
		customLegend = StatisticsPortal._isTableOrSplitOrDefault(args.customLegend, customInputs),
		customYears = args.customYears,
		startYear = args.startYear or Info.startYear,
		yearBreakdown = Logic.readBool(args.yearBreakdown),
		removeEmptyCategories = Logic.readBool(args.removeEmptyCategories),
		removeEmptySeries = Logic.readBool(args.removeEmptySeries),
		chartType = args.chartType or 'bar',
		stackType = args.stackType or 'total',
		isForTeam = isForTeam,
		opponentName = opponentName,
		opponentType = isForTeam and Opponent.team or Opponent.solo,
		maxOpponents = tonumber(args.maxOpponents) or MAX_OPPONENT_LIMIT,
		height = tonumber(args.height) or 400,
		width = tonumber(args.width) or 1400,
	}
end


---@param tablePlace number
---@param item table
---@param config table
---@return number
function StatisticsPortal._defaultProcessFunction(tablePlace, item, config)
	local earnings
	if String.isNotEmpty(config.opponentName) and item.opponenttype == Opponent.team then
		earnings = config.isForTeam and item.prizemoney or item.individualprizemoney
	else
		earnings = item.prizemoney
	end
	return tablePlace + Math.round(earnings or 0, DEFAULT_ROUND_PRECISION)
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


---@param args table
---@return table, table
function StatisticsPortal._returnCustomYears(args)
	args.startYear = tonumber(args.startYear) or Info.startYear
	local yearTable
	local defaultYearTable = Array.range(args.startYear, CURRENT_YEAR)
	if String.isNotEmpty(args.customYears) then
		yearTable = Array.map(
			StatisticsPortal._isTableOrSplitOrDefault(args.customYears),
			function(tier)
				return tonumber(tier)
			end
		)
		table.insert(yearTable, CURRENT_YEAR)
		return yearTable, defaultYearTable
	else
		return defaultYearTable, defaultYearTable
	end
end


---@param prevYear number
---@param yearValue number
---@return string|number
function StatisticsPortal._returnCustomYearText(prevYear, yearValue)
	return (prevYear == yearValue) and yearValue or
		'\'' .. (string.sub(prevYear, 3, 4) .. '-' .. string.sub(yearValue, 3, 4))
end


---@param arrays table
---@return table
function StatisticsPortal._addArrays(arrays)
	return Array.map(arrays[1], function(_, index)
		return Array.reduce(Array.map(arrays, Operator.property(index)), Operator.add)
	end)
end

return Class.export(StatisticsPortal, {exports = {
	'gameEarningsChart',
	'modeEarningsChart',
	'topEarningsChart',
	'coverageStatistics',
	'coverageMatchTable',
	'coverageTournamentTable',
	'prizepoolBreakdown',
	'pieChartBreakdown',
	'earningsTable',
	'playerAgeTable',
}})
