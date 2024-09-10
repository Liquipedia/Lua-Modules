---
-- @Liquipedia
-- wiki=commons
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local DateExt = require('Module:Date/Ext')
local Game = require('Module:Game')
local Info = require('Module:Info')
local LeagueIcon = require('Module:LeagueIcon')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Medals = require('Module:Medals')
local Operator = require('Module:Operator')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Count = Lua.import('Module:Count')

local CURRENCY_FORMAT_OPTIONS = {dashIfZero = true, displayCurrencyCode = false, formatValue = true}
local CURRENT_YEAR = tonumber(os.date('%Y')) --[[@as integer]]
local DATE = os.date('%F') --[[@as string]]
local TIMESTAMP = DateExt.readTimestamp(DATE) --[[@as integer]]
local DEFAULT_ALLOWED_PLACES = {'1', '2', '3', '1-2', '1-3', '2-3', '2-4', '3-4'}
local DEFAULT_ROUND_PRECISION = Info.defaultRoundPrecision or 2
local LANG = mw.getContentLanguage()
local MAX_OPPONENT_LIMIT = 10
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
---@return Html
function StatisticsPortal.gameEarningsChart(args)
	args = args or {}

	local params = {
		variable = 'game',
		processFunction = StatisticsPortal._defaultProcessFunction,
		catLabel = 'Year',
		defaultInputs = GAMES,
		axisRotate = tonumber(args.axisRotate),
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local yearSeriesData = StatisticsPortal._cacheModeEarningsData(config)
	return StatisticsPortal._buildChartData(config, yearSeriesData, config.customLegend, true)
end


---@param args table?
---@return Html
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
---@return Html
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

	local yearSeriesData = Array.map(Array.range(config.startYear, tonumber(args.year) or CURRENT_YEAR), function(year)
		return Array.map(Array.reverse(topEarningsList), function(teamData)
			return teamData.extradata['earningsin' .. year] or 0
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
---@return Html
function StatisticsPortal.coverageStatistics(args)
	args = args or {}
	args.alignSide = Logic.readBool(args.alignSide)

	local wrapper = mw.html.create('div')
	local tournamentTable = wrapper:tag('div')
	local matchTable = wrapper:tag('div')

	if args.alignSide then
		tournamentTable
			:addClass('template-box')
			:css('padding-right', '2em')
		matchTable
			:addClass('template-box')
			:css('padding-right', '2em')
	end

	tournamentTable:node(StatisticsPortal.coverageTournamentTable(args))
	matchTable:node(StatisticsPortal.coverageMatchTable(args))

	return wrapper
end


---@param args table?
---@return Html
function StatisticsPortal.coverageMatchTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES)

	local matchTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped')

	matchTable:tag('caption')
		:wikitext(args.matchTableTitle or (Logic.readBool(args.alignSide) and '<br>' or ''))
		:css('text-align', 'center')

	local matchHeader = matchTable:tag('tr')

	if Logic.readBool(args.multiGame) then
		matchHeader:tag('th')
			:wikitext('Game')
	end

	matchHeader
		:tag('th'):wikitext(args.matchesTitle or 'Matches'):done()
		:tag('th'):wikitext(args.gamesTitle or 'Games')

	if Logic.readBool(args.multiGame) then
		for _, game in Table.iter.spairs(args.customGames) do
			matchTable:node(StatisticsPortal._coverageMatchTableRow(args, {
						game = game,
						year = args.year
					}
				)
			)
		end
	end

	matchTable:node(StatisticsPortal._coverageMatchTableRow(args, {
				year = args.year
			}
		)
	)

	return matchTable
end


---@param args table
---@param parameters table
---@return Html
function StatisticsPortal._coverageMatchTableRow(args, parameters)
	local resultsRow = mw.html.create('tr')
	local tagType = (Logic.readBool(args.multiGame) and not parameters.game) and 'th' or 'td'

	if Logic.readBool(args.multiGame) then
		resultsRow:node(StatisticsPortal._returnGameCell(args, parameters, tagType))
	end

	local matchCountValue
	local gameCountValue

	if Info.config.match2.status == 2 then
		matchCountValue = Count.match2gamesData(parameters)
		gameCountValue = Count.match2(parameters)
	else
		matchCountValue = Count.matches(parameters)
		gameCountValue = Count.games(parameters)
	end

	resultsRow:tag(tagType)
		:wikitext(LANG:formatNum(matchCountValue))
		:css('text-align', 'right')

	resultsRow:tag(tagType)
		:wikitext(LANG:formatNum(gameCountValue))
		:css('text-align', 'right')

	return resultsRow
end


---@param args table?
---@return Html
function StatisticsPortal.coverageTournamentTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES)
	args.customTiers = StatisticsPortal._isTableOrSplitOrDefault(args.customTiers)
	args.customTiers = args.customTiers and Array.map(args.customTiers, function(tier) return tonumber(tier) end)
	args.includeTierTypes = StatisticsPortal._isTableOrSplitOrDefault(args.includeTierTypes, DEFAULT_TIERTYPES)
	args.showTierTypes = StatisticsPortal._isTableOrSplitOrDefault(args.showTierTypes, {})
	args.filterByStatus = Logic.readBool(args.filterByStatus) or false

	local tournamentTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped')

	tournamentTable:tag('caption')
		:wikitext(args.tournamentTableTitle or 'Tournaments Covered')
		:css('text-align', 'center')

	tournamentTable:node(StatisticsPortal._coverageTournamentTableHeader(args))

	if Logic.readBool(args.multiGame) then
		for _, game in Table.iter.spairs(args.customGames) do
			tournamentTable:node(StatisticsPortal._coverageTournamentTableRow(args, {
						game = game,
						year = args.year,
						filterByStatus = args.filterByStatus
					}
				)
			)
		end
	end

	tournamentTable:node(StatisticsPortal._coverageTournamentTableRow(args, {
				year = args.year,
				filterByStatus = args.filterByStatus
			}
		)
	)

	return tournamentTable
end


---@param args table
---@param parameters table
---@return Html
function StatisticsPortal._coverageTournamentTableRow(args, parameters)
	local resultsRow = mw.html.create('tr')
	local tagType = (Logic.readBool(args.multiGame) and not parameters.game) and 'th' or 'td'
	local runningTally = 0

	if Logic.readBool(args.multiGame) then
		resultsRow:node(StatisticsPortal._returnGameCell(args, parameters, tagType))
	end

	local countData = Count.tournamentsByTier(parameters)
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
				resultsRow:tag(tagType)
					:wikitext(LANG:formatNum(tournamentCount))
					:css('text-align', 'right')
			end
		end
	end

	if #args.showTierTypes then
		for _, tierTypeValue in ipairs(args.showTierTypes) do
			local _, tierTypeData = Tier.raw(nil, tierTypeValue)
			if tierTypeData then
				local count = Array.reduce(
					Array.map(Array.extractValues(countData),
						function(typeCounts, index)
							return Table.extract(typeCounts, tierTypeValue) or 0
						end
					),
					Operator.add, 0
				)
				runningTally = runningTally + count
				resultsRow:tag(tagType)
					:wikitext(LANG:formatNum(count))
					:css('text-align', 'right')
			end
		end
	end

	if String.isNotEmpty(args.showOther) then
		local countOther = Array.reduce(
			Array.flatten(Array.map(Array.extractValues(countData),
				function(typeCounts, index)
					return Table.isNotEmpty(typeCounts) and Array.extractValues(typeCounts) or 0
				end
			)), Operator.add, 0)
		runningTally = runningTally + countOther
		resultsRow:tag(tagType)
			:wikitext(LANG:formatNum(countOther))
			:css('text-align', 'right')
	end

	resultsRow:tag(tagType)
		:wikitext(LANG:formatNum(runningTally))
		:css('text-align', 'right')

	return resultsRow:allDone()
end


---@param args table
---@return Html
function StatisticsPortal._coverageTournamentTableHeader(args)
	local headerRow = mw.html.create('tr')

	if Logic.readBool(args.multiGame) then
		headerRow:tag('th')
			:wikitext('Game')
	end

	for headerIndex, headerValue in Tier.iterate('tiers') do
		if String.isNotEmpty(headerValue.value) and tonumber(headerValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == headerIndex
			end) then
				headerRow:tag('th')
					:wikitext(Tier.displaySingle(headerValue, {link = true}))
			end
		end
	end

	if #args.showTierTypes then
		for _, tierTypeValue in ipairs(args.showTierTypes) do
			local _, tierTypeData = Tier.raw(nil, tierTypeValue)
			if tierTypeData then
				headerRow:tag('th')
					:wikitext(Tier.displaySingle(tierTypeData, {link = true, short = true}))
			end
		end
	end

	if String.isNotEmpty(args.showOther) then
		headerRow:tag('th')
			:wikitext(Abbreviation.make('Other', 'Includes otherwise unlisted tournaments (e.g. with tiertypes, misc.)'))
	end

	headerRow:tag('th')
		:wikitext('Total')

	return headerRow
end

--[[
Section: Prizepool Breakdown
]]--


---@param args table?
---@return Html
function StatisticsPortal.prizepoolBreakdown(args)
	args = args or {}
	args.showAverage = Logic.readBool(args.showAverage)
	args.startYear = tonumber(args.startYear) or Info.startYear

	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(args)
	local rowLimit = Math.round(((Logic.readBool(args.showAverage) and 1 or 0) + 1 + Table.size(yearTable)) / 2)

	local wrapper = mw.html.create('div')

	local prizepoolTable = wrapper:tag('table')
		:addClass('wikitable wikitable-striped')
		:css('width', '100%')
		:css('text-align', 'center')

	prizepoolTable:tag('caption')
		:wikitext('Prize Money Awarded')
		:css('text-align', 'center')

	local headerRow = prizepoolTable:tag('tr')
	local resultsRow = prizepoolTable:tag('tr')

	local prizepoolSum = 0
	local prevYear = args.startYear
	local colIndex = 1

	for _, yearValue in pairs(defaultYearTable) do
		local conditions = StatisticsPortal._returnBaseConditions()

		if args.game then
			conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
		end

		conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate_year'), Comparator.eq, yearValue)
			}
		}

		if yearValue == CURRENT_YEAR then
			conditions:add{ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)}
		end

		local data = mw.ext.LiquipediaDB.lpdb('tournament', {
				query = 'sum::prizepool',
				limit = MAX_QUERY_LIMIT,
				conditions = conditions:toString(),
				order = 'sortdate desc',
			}
		)

		prizepoolSum = prizepoolSum + (tonumber(data[1].sum_prizepool) or 0)

		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			headerRow:tag('th')
				:wikitext(StatisticsPortal._returnCustomYearText(prevYear, yearValue))
			resultsRow:tag('td')
				:wikitext(Currency.display(US_DOLLAR, prizepoolSum or 0, CURRENCY_FORMAT_OPTIONS))
			prizepoolSum = 0
			prevYear = yearValue + 1
			colIndex = colIndex + 1
		end

		if colIndex > rowLimit and rowLimit > 8 then
			colIndex = 1
			wrapper:tag('span'):wikitext('<br>')

			prizepoolTable = wrapper:tag('table')
				:addClass('wikitable wikitable-striped')
				:css('width', '100%')
				:css('text-align', 'center')

			headerRow = prizepoolTable:tag('tr')
			resultsRow = prizepoolTable:tag('tr')
		end
	end

	local conditions = StatisticsPortal._returnBaseConditions()

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
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
	headerRow:tag('th')
		:wikitext('Total')
	resultsRow:tag('td')
		:wikitext(Currency.display(US_DOLLAR, totalPrizePool, CURRENCY_FORMAT_OPTIONS))
		:css('font-weight', 'bold')

	if Logic.readBool(args.showAverage) then
		headerRow:tag('th')
			:tag('abbr')
			:attr('title', 'Average Prizepool per Tournament')
			:wikitext('AVG PPT')
		resultsRow:tag('td')
			:wikitext(Currency.display(US_DOLLAR, totalPrizePool / (Count.tournaments() or 1), CURRENCY_FORMAT_OPTIONS))
			:css('font-weight', 'bold')
	end

	return wrapper
end


---@param args table?
---@return Html
function StatisticsPortal.pieChartBreakdown(args)
	args = args or {}
	args.height = args.height or 300
	args.width = args.width or 400
	args.hideKey = Logic.readBool(args.hideKey)
	args.detailedKey = Logic.readBool(args.detailedKey)
	args.multiGame = Logic.readBool(args.multiGame)
	args.multiMode = Logic.readBool(args.multiMode)

	local wrapper = mw.html.create('div')

	wrapper:node(mw.html.create('div')
		:addClass('template-box')
		:css('padding-right', '5em')
		:css('font-size', '85%')
		:css('text-align', 'center')
		:wikitext('Tournament Type')
		:node(StatisticsPortal._getPieChartData(
			args, 'type', 'Mixed', TYPES
		))
	)

	if args.multiGame then
		wrapper:node(mw.html.create('div')
			:addClass('template-box')
			:css('padding-right', '5em')
			:css('font-size', '85%')
			:css('text-align', 'center')
			:wikitext('Game Breakdown')
			:node(StatisticsPortal._getPieChartData(
				args, 'game', 'Other', StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES)
			))
		)
	end

	if args.multiMode then
		wrapper:node(mw.html.create('div')
			:addClass('template-box')
			:css('padding-right', '5em')
			:css('font-size', '85%')
			:css('text-align', 'center')
			:wikitext('Mode Breakdown')
			:node(StatisticsPortal._getPieChartData(
				args, 'mode', 'Other', StatisticsPortal._isTableOrSplitOrDefault(args.customModes, {'Team'})
			))
		)
	end

	if Logic.readBool(args.hideKey) then
		return wrapper
	end

	if Logic.readBool(args.detailedKey) then
		wrapper:node(mw.html.create('div')
			:addClass('template-box')
			:node(StatisticsPortal.prizepoolBreakdown(args))
		)
		return wrapper
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
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'sum::prizepool',
		limit = MAX_QUERY_LIMIT,
		conditions = conditions:toString(),
		order = 'sortdate desc',
	})

	local summaryTable = mw.html.create('table')
		:addClass('wikitable')
		:css('text-align', 'center')
		:css('font-weight', 'bold')

	summaryTable:tag('tr')
		:tag('th'):wikitext('Total prize money awarded')

	summaryTable:tag('tr')
		:tag('td')
		:wikitext(Currency.display(US_DOLLAR, data[1].sum_prizepool or 0, CURRENCY_FORMAT_OPTIONS))
		:attr('data-sort-type', 'currency')
		:css('font-weight', 'bold')

	wrapper:node(mw.html.create('div')
		:addClass('template-box')
		:css('padding-right', '1em')
		:node(summaryTable)
	)

	return wrapper
end


---@param args table?
---@return Html
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
		if String.isNotEmpty(args.year) and a.extradata then
			return tonumber(a.extradata['earningsin'..args.year]) or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	local opponentData

	if args.opponentType == Opponent.team then
		opponentData = StatisticsPortal._getTeams()
	elseif args.opponentType == Opponent.solo then
		opponentData = StatisticsPortal._getPlayers()
	end

	table.sort(opponentData, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	local opponentPlacements = StatisticsPortal._cacheOpponentPlacementData(args)

	local tbl = mw.html.create('table')
		:addClass('wikitable wikitable-striped wikitable-bordered sortable')
		:css('margin-left', '0px')
		:css('margin-right', 'auto')
		:css('width', '100%')

	tbl:node(StatisticsPortal._earningsTableHeader(args))

	for opponentIndex, opponent in ipairs(opponentData) do
		local opponentDisplay
		local earnings = earningsFunction(opponent)

		if opponentIndex > args.limit or earnings < args.minimumEarnings then break end

		if args.opponentType == Opponent.team then
			opponentDisplay = OpponentDisplay.BlockOpponent{
				opponent = {template = opponent.template, type = Opponent.team},
				teamStyle = 'standard',
			}
		else
			opponentDisplay = OpponentDisplay.BlockOpponent{
				opponent = StatisticsPortal._toOpponent(opponent),
			}
		end
		local placements = opponentPlacements[opponent.pagename] or {}
		tbl:node(StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay))
	end

	return mw.html.create('div'):addClass('table-responsive'):node(tbl)
end


--[[
Section: Player Age Table Breakdown
]]--


---@param args table?
---@return Html
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

	local playerData = StatisticsPortal._getPlayers(args.limit, conditions:toString(), args.order)

	local tbl = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('margin-left', '0px')
		:css('margin-right', 'auto')

	tbl:tag('tr')
		:tag('th'):wikitext('ID'):addClass('unsortable'):done()
		:tag('th'):wikitext('Age')

	for _, player in ipairs(playerData) do
		local birthdate = DateExt.readTimestamp(player.birthdate) --[[@as integer]]
		local age = os.date('*t', os.difftime(TIMESTAMP, birthdate))
		local yearAge = age.year - 1970
		local dayAge = age.yday - 1

		tbl:tag('tr')
			:tag('td')
				:node(OpponentDisplay.BlockOpponent{
					opponent = StatisticsPortal._toOpponent(player),
					showPlayerTeam = true,
				}):done()
			:tag('td')
				:wikitext(yearAge .. ' years, ' .. dayAge .. ' days')
	end

	return mw.html.create('div'):addClass('table-responsive'):node(tbl)
end


--[[
Section: Query Functions
]]--


---@param limit number?
---@param addConditions string?
---@param addOrder string?
---@return table
function StatisticsPortal._getPlayers(limit, addConditions, addOrder)
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'pagename, id, nationality, earnings, extradata, birthdate, team',
		conditions = addConditions or '',
		order = addOrder,
		limit = limit or MAX_QUERY_LIMIT,
	})

	return data
end


---@param limit number?
---@param addConditions string?
---@param addOrder string?
---@return table
function StatisticsPortal._getTeams(limit, addConditions, addOrder)
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		query = 'pagename, name, template, earnings, extradata',
		conditions = addConditions or '',
		order = addOrder,
		limit = limit or MAX_QUERY_LIMIT,
	})

	return data
end


---@param args table
---@param config table
---@return table
function StatisticsPortal._getOpponentEarningsData(args, config)
	local opponentType = config.opponentType == Opponent.team and 'team' or 'player'
	local queryFields
	if opponentType == Opponent.team then
		queryFields = 'pagename, name, template, earnings, extradata'
	else
		queryFields = 'pagename, id, nationality, earnings, extradata, birthdate, team'
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
		if String.isNotEmpty(args.year) and a.extradata then
			return tonumber(a.extradata['earningsin'..args.year]) or 0
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
---@return table
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
		LPDBConditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
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
			entry.name = Game.abbreviation{game = entry.name} or entry.name
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
		local year = tonumber(item.date:sub(1, 4))
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
---@param tagType string
---@return Html
function StatisticsPortal._returnGameCell(args, parameters, tagType)
	local gameCell = mw.html.create(tagType)
	if Logic.readBool(args.multiGame) and not parameters.game then
		gameCell:wikitext('Total')
	elseif Logic.readBool(args.multiGame) then
		gameCell:wikitext(parameters.game)
	end
	return gameCell
end


---@param args table
---@return Html
function StatisticsPortal._earningsTableHeader(args)
	local columnText = args.opponentType == Opponent.team and 'Organization' or 'Player'

	local row = mw.html.create('tr')
		:tag('th'):wikitext('#'):addClass('unsortable'):done()
		:tag('th'):wikitext(columnText):addClass('unsortable'):done()
		:tag('th'):wikitext('Achievements'):css('width', '200px'):addClass('unsortable'):done()
		:tag('th'):node(Medals.display{medal = 1}):done()
		:tag('th'):node(Medals.display{medal = 2}):done()
		:tag('th'):node(Medals.display{medal = 3}):done()

	if Logic.readBool(args.displayShowMatches) then
		row:tag('th'):wikitext('Show<br>Match')
	end

	row:tag('th')
		:tag('abbr')
		:attr('title', 'Total earnings across all games')
		:wikitext('Earnings')

	return row
end


---@param args table
---@param placements table
---@param earnings number
---@param opponentIndex number
---@param opponentDisplay Html
---@return Html
function StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay)
	local row = mw.html.create('tr')
		:css('line-height', '25px')
		:css('text-align', 'center')
		:tag('td'):wikitext(opponentIndex):done()
		:tag('td'):css('text-align', 'left'):node(opponentDisplay):done()
		:tag('td'):wikitext(StatisticsPortal._achievementsDisplay(placements.sWinData or {})):done()
		:tag('td'):wikitext(placements['1'] or '0'):done()
		:tag('td'):wikitext(placements['2'] or '0'):done()
		:tag('td'):wikitext(placements['3'] or '0'):done()

	if Logic.readBool(args.displayShowMatches) then
		row:tag('td'):wikitext(placements.showWins or 0)
	end

	row:tag('td')
		:css('text-align', 'right')
		:wikitext(Currency.display(US_DOLLAR, earnings, CURRENCY_FORMAT_OPTIONS))

	return row
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
---@return Html
function StatisticsPortal._drawChart(config, chartData)
	return mw.html.create('div')
		:addClass('table-responsive')
		:node(mw.ext.Charts.chart({
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
	)
end


---@param args table
---@param chartData table
---@return Html
function StatisticsPortal._drawPieChart(args, chartData)
	return mw.html.create('div')
		:addClass('table-responsive')
		:node(mw.ext.Charts.piechart{
			size = {
				height = args.height,
				width = args.width
			},
			data = chartData
		}
	)
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
---@return Html
function StatisticsPortal._buildChartData(config, yearSeriesData, nonYearCategories, transpose)
	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(config)
	local prevYear = config.startYear

	local yearList = {}
	local chartData = {}
	local seriesData = {}
	local earningsTable = Array.map(Array.range(1, Table.size(nonYearCategories)), function() return 0 end)

	for yearIndex, yearValue in pairs(defaultYearTable) do
		earningsTable = StatisticsPortal._addArrays({earningsTable, yearSeriesData[yearIndex]})
		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			local yearText = StatisticsPortal._returnCustomYearText(prevYear, yearValue)
			table.insert(yearList, yearText)
			table.insert(seriesData, earningsTable)
			prevYear = yearValue + 1
			earningsTable = Array.map(Array.range(1, Table.size(nonYearCategories)), function() return 0 end)
		end
	end

	local categoryNames = nonYearCategories
	local seriesNames = yearList

	if transpose == true then
		seriesData = Array.map(Array.range(1, Table.size(nonYearCategories)), function(index)
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
					return Logic.readBool(isEmptyCategory[catIndex]) end)
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
	---@cast input -nil
	return Array.map(mw.text.split(input, ',', true), String.trim)
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


return Class.export(StatisticsPortal)
