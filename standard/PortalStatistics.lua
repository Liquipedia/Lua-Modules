
local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local DateExt = require('Module:Date/Ext')
local Info = require('Module:Info')
local LeagueIcon = require('Module:LeagueIcon')
local Lpdb = require('Module:Lpdb')
local Math = require('Module:Math')
local Medal = require('Module:Medal')
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

local Count = require('Module:Count/dev')
local PieChart = require('Module:Tournaments breakdown pie chart/dev')

local CURRENT_YEAR = tonumber(os.date('%Y'))
local DATE = os.date('%F')
local TIMESTAMP = DateExt.readTimestamp(DATE)
local DEFAULT_ALLOWED_PLACES = '1,2,3,1-2,2-3,2-4,3-4'
local DEFAULT_ROUND_PRECISION = Info.defaultRoundPrecision or 2
local LANG = mw.getContentLanguage()
local MODES = Array.map(mw.text.split('solo, team, other', ','), String.trim)
local GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value['name']
end)


local StatisticsPortal = {}


--[[
Section: Chart Entry Functions
]] --


function StatisticsPortal.gameEarningsChart(args)

	args = args or {}

	local processFunction = function(tablePlace, item, config)
		local earnings
		if String.isNotEmpty(config.opponentName) and item.opponenttype == Opponent.team then
			earnings = config.isForTeam and item.prizemoney or item.individualprizemoney
		else
			earnings = item.prizemoney
		end
		return tablePlace + Math._round(earnings or 0, DEFAULT_ROUND_PRECISION)
	end

	local params = {
		variable = 'game',
		processFunction = processFunction,
		catLabel = 'Year',
		defaultInputs = GAMES,
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local yearSeriesData = StatisticsPortal._cacheModeEarningsData(config)

	return StatisticsPortal._buildChartData(config, yearSeriesData, config.customLegend, true)
end

function StatisticsPortal.modeEarningsChart(args)

	args = args or {}

	local processFunction = function(tablePlace, item, config)
		local earnings
		if String.isNotEmpty(config.opponentName) and item.opponenttype == Opponent.team then
			earnings = config.isForTeam and item.prizemoney or item.individualprizemoney
		else
			earnings = item.prizemoney
		end
		return tablePlace + Math._round(earnings or 0, DEFAULT_ROUND_PRECISION)
	end

	local params = {
		variable = 'opponenttype',
		processFunction = processFunction,
		catLabel = 'Year',
		defaultInputs = MODES,
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local yearSeriesData = StatisticsPortal._cacheModeEarningsData(config)

	return StatisticsPortal._buildChartData(config, yearSeriesData, config.customLegend, true)
end


function StatisticsPortal.topEarningsChart(args)

	args = args or {}
	args.limit = tonumber(args.limit) or 10

	local params = {
		variable = nil,
		processFunction = nil,
		catLabel = Logic.readBool(args.isForTeam) and 'Teams' or 'Players',
		flipAxes = true,
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('earnings'), Comparator.gt, 0)}
	local topEarningsList

	if config.opponentType == Opponent.team then
		topEarningsList = StatisticsPortal._getTeams(
			args.limit,
			conditions:toString(),
			'sum::earnings desc',
			'earnings asc')
	elseif config.opponentType == Opponent.solo then
		topEarningsList = StatisticsPortal._getPlayers(
			args.limit,
			conditions:toString(),
			'sum::earnings desc',
			'earnings asc')
	else
		mw.log(config.opponentType .. ' is not a valid opponent type. Choose either \'solo\' or \'team\'.')
		return
	end

	local yearSeriesData = Array.map(Array.range(config.startYear, CURRENT_YEAR), function(year)
			return Array.map(Array.reverse(topEarningsList), function(teamData)
					return teamData.extradata['earningsin'..year] or 0
				end)
		end)

	local opponentNames = Array.map(Array.reverse(topEarningsList), function(opponent)
				return config.opponentType == Opponent.team and opponent['name'] or opponent['id']
			end)

	if Logic.readBool(config.yearBreakdown) then
		return StatisticsPortal._buildChartData(config, yearSeriesData, opponentNames)
	else
		local chartData = {}
		chartData[1] = {
			['name'] = 'Total Earnings',
			['type'] = 'bar',
			['data'] = StatisticsPortal._addArrays(yearSeriesData),
		}

		config['yAxis'] = {type = 'value', name = 'Earnings ($USD)'}
		config['xAxis'] = {type = 'category', name = config.catLabel, data = opponentNames}
		config['customLegend'] = config['customLegend'] or config.customInputs
		return StatisticsPortal._drawChart(config, chartData)
	end
end


--[[
Section: Coverage Breakdown
]] --


function StatisticsPortal.coverageStatistics(args)

	args = args or {}
	args.alignSide = Logic.readBoolOrNil(args.alignSide)

	local wrapper = mw.html.create('div')
	local TournamentTable = wrapper:tag('div')
	local matchTable = wrapper:tag('div')

	if args.alignSide then
		TournamentTable
			:addClass('template-box')
			:css('padding-right','2em')
		matchTable
			:addClass('template-box')
			:css('padding-right','2em')
	end

	TournamentTable:node(StatisticsPortal.coverageTournamentTable(args))
	matchTable:node(StatisticsPortal.coverageMatchTable(args))

	return wrapper
end


function StatisticsPortal.coverageMatchTable(args)

	args = args or {}
	args.multiGame = Logic.readBoolOrNil(args.multiGame) or false
	args.customGames = (type(args.customGames) == 'table' and args.customGames)
		or (String.isNotEmpty(args.customGames) and Array.map(mw.text.split(args.customGames, ','), String.trim))
		or GAMES

	local matchTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped')

	matchTable:tag('caption')
		:wikitext(args.matchTableTitle or (Logic.readBool(args.alignSide) and '<br>' or ''))
		:css('text-align','center')

	local matchHeader = matchTable:tag('tr')

	if Logic.readBool(args.multiGame) then
		matchHeader:tag('th')
			:wikitext('Game')
	end

	matchHeader
		:tag('th'):wikitext(args.matchesTitle or 'Matches')
		:tag('th'):wikitext(args.gamesTitle or 'Games')

	if Logic.readBool(args.multiGame) then
		for _, game in Table.iter.spairs(args.customGames) do
			matchTable:node(StatisticsPortal._coverageMatchTableRow(args, {game = game, year = args.year}))
		end
	end

	matchTable:node(StatisticsPortal._coverageMatchTableRow(args, {year = args.year}))

	return matchTable
end


function StatisticsPortal._coverageMatchTableRow(args, parameters)

	local resultsRow = mw.html.create('tr')
	local tagtype = 'td'

	if Logic.readBool(args.multiGame) and parameters['game'] == nil then
		tagtype = 'th'
		resultsRow:tag(tagtype)
			:wikitext('Total')
	elseif Logic.readBool(args.multiGame) and parameters['game'] ~= nil then
		resultsRow:tag(tagtype)
			:wikitext(parameters['game'])
	end

	resultsRow:tag(tagtype)
		:wikitext(LANG:formatNum(Count.matches(parameters)))
		:css('text-align','right')

	resultsRow:tag(tagtype)
		:wikitext(LANG:formatNum(Count.games(parameters)))
		:css('text-align','right')

	return resultsRow:allDone()
end


function StatisticsPortal.coverageTournamentTable(args)

	args = args or {}
	args.multiGame = Logic.readBoolOrNil(args.multiGame) or false
	args.customGames = String.isNotEmpty(args.customGames) and
		Array.map(mw.text.split(args.customGames, ','), String.trim) or GAMES
	args.customTiers = String.isNotEmpty(args.customTiers) and
		Array.map(mw.text.split(args.customTiers, ','), function(item)
			return tonumber(String.trim(item))
		end)

	local tournamentTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped')

	tournamentTable:tag('caption')
		:wikitext(args.tournamentTableTitle or 'Tournaments Covered')
		:css('text-align','center')

	tournamentTable:node(StatisticsPortal._coverageTournamentTableHeader(args))

	if Logic.readBool(args.multiGame) then
		for _, game in Table.iter.spairs(args.customGames) do
			tournamentTable:node(StatisticsPortal._coverageTournamentTableRow(args, {game = game, year = args.year}))
		end
	end

	tournamentTable:node(StatisticsPortal._coverageTournamentTableRow(args, {year = args.year}))

	return tournamentTable
end


function StatisticsPortal._coverageTournamentTableRow(args, parameters)

	local resultsRow = mw.html.create('tr')
	local tagtype = 'td'
	local runningTally = 0

	if Logic.readBool(args.multiGame) and parameters['game'] == nil then
		tagtype = 'th'
		resultsRow:tag(tagtype):wikitext('Total')
	elseif Logic.readBool(args.multiGame) and parameters['game'] ~= nil then
		resultsRow:tag(tagtype):wikitext(parameters['game'])
	end

	for rowIndex, rowValue in Tier.iterate('tiers') do
		if String.isNotEmpty(rowValue.value) and tonumber(rowValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == rowIndex
			end) then
				local tournamentCount = Count.tournaments(Table.merge({liquipediatier = rowIndex}, parameters))
				runningTally = runningTally + tournamentCount
				resultsRow:tag(tagtype)
					:wikitext(LANG:formatNum(tournamentCount))
					:css('text-align','right')
			end
		end
	end

	if String.isNotEmpty(args.showOther) then
		resultsRow:tag(tagtype)
			:wikitext(LANG:formatNum(Count.totalTournaments(parameters) - runningTally))
			:css('text-align','right')
	end

	if String.isNotEmpty(args.showTierTypes) then
		for _, tierTypeValue in pairs(mw.text.split(args.showTierTypes, ',')) do
			local _, tierTypeData = Tier._raw(nil, tierTypeValue)
			if tierTypeData then
				resultsRow:tag(tagtype)
					:wikitext(LANG:formatNum(Count.tournaments(Table.merge({liquipediatiertype = LANG:ucfirst(tierTypeValue)}, parameters))))
					:css('text-align','right')
			end
		end
	end

	resultsRow:tag(tagtype)
		:wikitext(LANG:formatNum(Count.totalTournaments(parameters)))
		:css('text-align','right')

	return resultsRow:allDone()
end


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
					:wikitext(Tier.displaySingle(headerValue, {['link'] = true,}))
			end
		end
	end

	if String.isNotEmpty(args.showOther) then
		headerRow:tag('th')
			:wikitext('Other')
	end

	if String.isNotEmpty(args.showTierTypes) then
		for _, tierTypeValue in pairs(mw.text.split(args.showTierTypes, ',')) do
			local _, tierTypeData = Tier._raw(nil, tierTypeValue)
			if tierTypeData then
				headerRow:tag('th')
					:wikitext(Tier.displaySingle(tierTypeData, {['link'] = true, ['short'] = true,}))
			end
		end
	end

	headerRow:tag('th')
		:wikitext('Total')

	return headerRow
end

--[[
Section: Prizepool Breakdown
]]--

function StatisticsPortal.prizepoolBreakdown(args)

	args = args or {}
	args.showAverage = Logic.readBoolOrNil(args.showAverage)
	args.startYear = tonumber(args.startYear) or Info.startYear

	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(args)
	local rowLimit = Math._round(((Logic.readBool(args.showAverage) and 1 or 0) + 1 + Table.size(yearTable)) / 2, 0)

	local baseConditions = function () return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'delayed')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.gt, '0')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '')}
	end

	local wrapper = mw.html.create('div')

	local prizepoolTable = wrapper:tag('table')
		:addClass('wikitable wikitable-striped')
		:css('width','100%')
		:css('text-align','center')

	prizepoolTable:tag('caption')
		:wikitext('Prize Money Awarded')
		:css('text-align','center')

	local headerRow = prizepoolTable:tag('tr')
	local resultsRow = prizepoolTable:tag('tr')

	local prizepoolSum = 0
	local prevYear = args.startYear
	local colIndex = 1

	for _, yearValue in pairs(defaultYearTable) do
		local conditions = baseConditions()

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
				limit = 5000,
				conditions = conditions:toString(),
				order = 'sortdate desc',
			}
		)

		prizepoolSum = prizepoolSum + tonumber(data[1]['sum_prizepool'] or 0)

		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			headerRow:tag('th')
				:wikitext(StatisticsPortal._returnCustomYearText(prevYear, yearValue))
			resultsRow:tag('td')
				:wikitext((prizepoolSum ~= 0 and '$' or '') .. Currency.formatMoney(prizepoolSum or 0))
			prizepoolSum = 0
			prevYear = yearValue + 1
			colIndex = colIndex + 1
		end

		if colIndex > rowLimit and rowLimit > 8 then
			colIndex = 1
			wrapper:tag('span'):wikitext('<br>')

			prizepoolTable = wrapper:tag('table')
				:addClass('wikitable wikitable-striped')
				:css('width','100%')
				:css('text-align','center')

			headerRow = prizepoolTable:tag('tr')
			resultsRow = prizepoolTable:tag('tr')
		end
	end

	local conditions = baseConditions()

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)
		},
	}

	local totalPrizePool = mw.ext.LiquipediaDB.lpdb('tournament', {
			query = 'sum::prizepool',
			limit = 5000,
			conditions = conditions:toString(),
			order = 'sortdate desc',
		}
	)

	headerRow:tag('th')
		:wikitext('Total')
	resultsRow:tag('td')
		:wikitext('$' .. Currency.formatMoney(totalPrizePool[1]['sum_prizepool']))
		:css('font-weight','bold')

	if Logic.readBool(args.showAverage) then
		headerRow:tag('th')
			:tag('abbr')
			:attr('title', 'Average Prizepool per Tournament')
			:wikitext('AVG PPT')
		resultsRow:tag('td')
			:wikitext('$' .. Currency.formatMoney(totalPrizePool[1]['sum_prizepool'] / Count.totalTournaments()))
			:css('font-weight','bold')
	end

	return wrapper
end


function StatisticsPortal.pieChartBreakdown(args)

	args = args or {}
	args.hideKey = Logic.readBoolOrNil(args.hideKey)
	args.detailedKey = Logic.readBoolOrNil(args.detailedKey)

	local wrapper = mw.html.create('div')

	wrapper:node(mw.html.create('div')
		:addClass('template-box')
		:css('padding-right','1em')
		:node(PieChart.create({year = args.year, game = args.game}))
	)

	if Logic.readBool(args.hideKey) then
		return wrapper
	end

	if Logic.readBool(args.detailedKey) then
		wrapper:node(mw.html.create('div')
			:addClass('template-box')
			:css('padding-left','5em')
			:node(StatisticsPortal.prizepoolBreakdown(args))
		)
		return wrapper
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'delayed')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.gt, '0')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '')}

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

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'sum::prizepool',
		limit = 5000,
		conditions = conditions:toString(),
		order = 'sortdate desc',
	})

	local summaryTable = mw.html.create('table')
		:addClass('wikitable')
		:css('text-align','center')
		:css('font-weight','bold')

	summaryTable:tag('th')
		:wikitext('Total prize money awarded')

	summaryTable:tag('tr')
		:tag('td')
		:wikitext('$' .. Currency.formatMoney(data[1]['sum_prizepool'] or 0))
		:attr('data-sort-type', 'currency')
		:css('font-weight','bold')

	wrapper:node(mw.html.create('div')
		:addClass('template-box')
		:css('padding-right','1em')
		:node(summaryTable)
	)

	return wrapper
end


function StatisticsPortal.earningsTable(args)

	args = args or {}
	args.limit = tonumber(args.limit) or 20
	args.opponentType = args.opponentType or Opponent.team
	args.displayShowMatches = Logic.readBoolOrNil(args.displayShowMatches)
	args.allowedPlacements = Array.map(mw.text.split(args.allowedPlacements or DEFAULT_ALLOWED_PLACES, ','),
		String.trim
	)

	local earningsFunction = function (a)
		if String.isNotEmpty(args.year) and a.extradata then
			return tonumber(a.extradata['earningsin'..args.year] or 0)
		else
			return tonumber(a.earnings or 0)
		end
	end

	local opponentData

	if args.opponentType == Opponent.team then
		opponentData = StatisticsPortal._getTeams(5000, nil, nil, nil)
	elseif args.opponentType == Opponent.solo then
		opponentData = StatisticsPortal._getPlayers(5000, nil, nil, nil)
	else
		mw.log(args.opponentType .. ' is not a valid opponent type. Choose either \'solo\' or \'team\'.')
		return
	end

	table.sort(opponentData, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	local opponentPlacements = StatisticsPortal._cacheOpponentPlacementData(args)

	local table = mw.html.create('table')
		:addClass('wikitable wikitable-striped wikitable-bordered sortable')
		:css('margin-left', '0px')
		:css('margin-right', 'auto')
		:css('width', '100%')

	table:node(StatisticsPortal._earningsTableHeader(args))

	for opponentIndex, opponent in ipairs(opponentData) do
		local opponentDisplay
		local earnings = earningsFunction(opponent)

		if opponentIndex > args.limit or earnings < 1000 then break end

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
		local placements = opponentPlacements[opponent['pagename']] or {}
		table:node(StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay))
	end

	return mw.html.create('div'):node(table)
end


--[[
Section: Player Age Table Breakdown
]]--


function StatisticsPortal.playerAgeTable(args)

	args = args or {}
	args.earnings = args.earnings and tonumber(args.earnings) or 500
	args.limit = args.limit and tonumber(args.limit) or 20
	args.order = args.order and 'birthdate ' .. args.order or 'birthdate desc'

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, '1970-01-01')}
		:add{ConditionNode(ColumnName('deathdate'), Comparator.eq, '1970-01-01')}
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

	local playerData = StatisticsPortal._getPlayers(args.limit, conditions:toString(), args.order, nil)

	local table = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('margin-left','0px')
		:css('margin-right','auto')

	table:tag('tr')
		:tag('th'):wikitext('ID'):addClass('unsortable')
		:tag('th'):wikitext('Age')

	for _, player in ipairs(playerData) do

		local birthdate =  DateExt.readTimestamp(player.birthdate)
		local yearAge = math.floor(os.difftime(TIMESTAMP, birthdate)/(24 * 3600 * 365.25))
		local dayAge = Math._round(Math._mod(math.floor(os.difftime(TIMESTAMP, birthdate)/(24 * 3600)), 365.25), 0)

		table:tag('tr')
			:tag('td'):
				node(OpponentDisplay.BlockOpponent{
						opponent = StatisticsPortal._toOpponent(player),
						showPlayerTeam  = true,
					}
				)
			:tag('td')
				:wikitext(yearAge..' years, '..dayAge..' days')
	end

	return mw.html.create('div'):node(table)
end


--[[
Section: Query Functions
]]--


function StatisticsPortal._getPlayers(limit, addConditions, addOrder, addGroupBy)
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'pagename, id, nationality, earnings, extradata, birthdate, team',
		conditions = addConditions or '',
		order = addOrder,
		groupby = addGroupBy,
		limit = limit or 5000,
	})

	return data
end


function StatisticsPortal._getTeams(limit, addConditions, addOrder, addGroupBy)
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		query = 'pagename, name, template, earnings, extradata',
		conditions = addConditions or '',
		order = addOrder,
		groupby = addGroupBy,
		limit = limit or 5000,
	})

	return data
end


function StatisticsPortal._cacheModeEarningsData(config)

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('prizemoney'), Comparator.gt, 0)}
		:add{ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01')}
		:add{ConditionNode(ColumnName('date'), Comparator.lt, DATE)}

	if String.isNotEmpty(config.startYear) then
		conditions:add{ConditionNode(ColumnName('date_year'), Comparator.gt, (config.startYear - 1))}
	end

	if String.isNotEmpty(config.opponentName) then
		local teamConditions = ConditionTree(BooleanOperator.any)
			:add{ConditionNode(ColumnName('opponentname'), Comparator.eq, config.opponentName)}
		local prefix = config.opponentType == Opponent.team and 'team' or ''
		for index = 1, 30 do
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
		limit = 5000,
		query = 'opponenttype, prizemoney, individualprizemoney, date, game',
	}

	Lpdb.executeMassQuery('placement', queryParameters, processData)

	return Array.map(Array.extractValues(earningsData, Table.iter.spairs), function(value)
			return Array.map(config.customInputs, function(key)
						return value[key]
					end)
			end)
end


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
	mw.logObject(conditions:toString())
	local data = {}

	local queryParameters = {
		query = 'pagename, shortname, icon, icondark, '
				.. 'liquipediatier, liquipediatiertype, placement, '
				.. 'opponentplayers, opponentname, opponenttype',
		conditions = conditions:toString(),
		limit = 1000,
	}

	local function returnOpponent(item)
		local opponentNames = {}
		if args.opponentType == Opponent.solo then
			for playerIndex = 1,10 do
				local name = string.gsub(item.opponentplayers['p' .. playerIndex] or '', ' ', '_')
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
		for _, opponent in pairs(returnOpponent(item) or {}) do
			if not data[opponent] then
				data[opponent] = {['1'] = 0, ['2'] =  0, ['3'] = 0, ['showWins'] = 0, ['sWinData'] = {}}
			end
			if placement == '1' and item.liquipediatier == '1' and item.liquipediatiertype ~= 'Showmatch' then
				table.insert(data[opponent]['sWinData'], {
						['icon'] = item.icon,
						['icondark'] = item.icondark,
						['pagename'] = item.pagename,
						['shortname'] = item.shortname
					}
				)
			end
			if placement == '1' and item.liquipediatiertype == 'Showmatch' then
				data[opponent]['showWins'] = data[opponent]['showWins'] + 1
			elseif item.liquipediatiertype ~= 'Showmatch' then
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


function StatisticsPortal._earningsTableHeader(args)

	local columnText = args.opponentType == Opponent.team and 'Organization' or 'Player'

	local row = mw.html.create('tr')
		:tag('th'):wikitext('#'):addClass('unsortable')
		:tag('th'):wikitext(columnText):addClass('unsortable')
		:tag('th'):wikitext('Achievements'):css('width', '200px'):addClass('unsortable')
		:tag('th'):wikitext(Medal['1'])
		:tag('th'):wikitext(Medal['2'])
		:tag('th'):wikitext(Medal['3'])

	if Logic.readBool(args.displayShowMatches) then
		row:tag('th'):wikitext('Show<br>Match')
	end

	row:tag('th')
		:tag('abbr')
		:attr('title', 'Total earnings across all games')
		:wikitext('Earnings')

	return row:allDone()
end


function StatisticsPortal._earningsTableRow(args, placements, earnings, opponentIndex, opponentDisplay)

	local row = mw.html.create('tr')
		:css('line-height', '25px')
		:css('text-align', 'center')
		:tag('td'):wikitext(opponentIndex):done()
		:tag('td'):css('text-align', 'left'):node(opponentDisplay):done()
		:tag('td'):wikitext(StatisticsPortal._achievementsDisplay(placements['sWinData'] or {})):done()
		:tag('td'):wikitext(placements['1'] or '0'):done()
		:tag('td'):wikitext(placements['2'] or '0'):done()
		:tag('td'):wikitext(placements['3'] or '0')

	if Logic.readBool(args.displayShowMatches) then
		row:tag('td'):wikitext(placements.showWins or '0')
	end

	row:tag('td')
		:css('text-align', 'right')
		:wikitext('$' .. Currency.formatMoney(earnings))

	return row:allDone()
end


function StatisticsPortal._achievementsDisplay(data)
	local output = ''
	if data and type(data[1]) == 'table' then
		for _, item in ipairs(data) do
			item.icon = string.gsub(item.icon, 'File:', '')
			item.icondark = string.gsub(item.icondark or '', 'File:', '')
			item.icon = String.isNotEmpty(item.icon) and item.icon or 'Gold.png'  --'InfoboxIcon Tournament.png'
			output = output .. LeagueIcon.display{
				icon = item.icon,
				iconDark = item.icondark,
				link = item.pagename,
				name = item.shortname,
				options = { noTemplate = true },
			}
			output = output .. ' '
		end
	end
	return output
end


function StatisticsPortal._drawChart(config, chartData)
	return mw.html.create('div'):node(mw.ext.Charts.chart({
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


--[[
Section: Utility Functions
]]--


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
		local startsEmpty = true
		local lastNotEmpty = 1

		local isEmptyCategory = Array.map(Array.map(categoryNames, function(_, catIndex)
				local truthValue = Array.all(Array.map(seriesData, function(_, index)
					return seriesData[index][catIndex] end), function(value)
						return value == 0
					end)
				if truthValue == false then
					lastNotEmpty = catIndex
				end
				return truthValue
			end),
		function(value, index)
			if index > lastNotEmpty then
				return false
			elseif startsEmpty == true and value == true then
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
	end

	for seriesIndex, series in pairs(seriesNames) do
		if config.removeEmptySeries == true and Array.all(seriesData[seriesIndex], function(value)
			return value == 0
		end) then
			mw.logObject(series .. ' is empty')
		else
			table.insert(chartData, {
					name = series,
					type = 'bar',
					stack = 'total',
					data = seriesData[seriesIndex],
					emphasis = {focus = 'series'},
				}
			)
		end
	end

	config['yAxis'] = {type = 'value', name = 'Earnings ($USD)'}
	config['xAxis'] = {type = 'category', name = config.catLabel, data = categoryNames}
	config['customLegend'] = config['customLegend'] or seriesNames

	return StatisticsPortal._drawChart(config, chartData)
end


function StatisticsPortal._chartConfig(args, params)

	local isForTeam = String.isNotEmpty(args.team) or Logic.readBool(args.isForTeam)

	return {
		processFunction = params.processFunction or nil,
		variable = params.variable or nil,
		catLabel = params.catLabel,
		flipAxes = params.flipAxes or false,

		customLegend = String.isNotEmpty(args.customLegend) and
			Array.map(mw.text.split(args.customLegend, ','), String.trim) or args.customInputs,
		customInputs = args.customInputs,
		customYears = args.customYears,
		startYear = args.startYear or Info.startYear,
		yearBreakdown = Logic.readBoolOrNil(args.yearBreakdown),
		removeEmptyCategories = Logic.readBool(args.removeEmptyCategories) or false,
		removeEmptySeries = Logic.readBool(args.removeEmptySeries) or false,
		isForTeam = isForTeam,
		opponentName = isForTeam and args.team or args.player,
		opponentType = isForTeam and Opponent.team or Opponent.solo,
		height = args.height or 400,
		width = args.width or (200 + 65 * (CURRENT_YEAR - (args.startYear or Info.startYear))),
	}
end


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


function StatisticsPortal._returnCustomYears(args)

	args.startYear = tonumber(args.startYear) or Info.startYear
	local yearTable
	local defaultYearTable = Array.range(args.startYear, CURRENT_YEAR)

	if String.isNotEmpty(args.customYears) then
		yearTable = Array.map(mw.text.split(args.customYears .. ',' .. CURRENT_YEAR, ','), function(item)
			return tonumber(String.trim(item))
		end)
		return yearTable, defaultYearTable
	else
		return defaultYearTable, defaultYearTable
	end
end


function StatisticsPortal._returnCustomYearText(prevYear, yearValue)
	return (prevYear == yearValue) and tostring(yearValue) or
		'\'' .. (string.sub(tostring(prevYear), 3, 4) .. '-' .. string.sub(tostring(yearValue), 3, 4))
end


function StatisticsPortal._addArrays(arrays)
	return Array.map(arrays[1], function(_, index)
		return Array.reduce(Array.map(arrays, Operator.property(index)), Operator.add)
	end)
end


return Class.export(StatisticsPortal)
