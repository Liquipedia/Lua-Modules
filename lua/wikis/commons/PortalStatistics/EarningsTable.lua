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
local Info = Lua.import('Module:Info', {loadData = true})
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
local MAX_PLAYERS_PER_PLACEMENT = Info.config.defaultMaxPlayersPerPlacement or 10
local MAX_QUERY_LIMIT = 5000
local PLAYER_BATCH_SIZE = 5

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
	args.maxAchievements = tonumber(args.maxAchievements)

	local hasYear = String.isNotEmpty(args.year)
	local earningsFunction = function (a)
		if hasYear then
			return a.earningsbyyear[tonumber(args.year)] or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	-- Total earnings are a plain column, so LPDB can filter and order them and only the displayed rows are fetched.
	-- Earnings by year are in a json field, so for a given year everything above the minimum is sorted here.
	-- The yearly earnings can never exceed the total earnings, so filtering on the total is safe for both.
	local queryLimit = (not hasYear) and args.limit or nil
	local queryOrder = (not hasYear) and 'earnings desc' or nil
	local earningsCondition = ConditionNode(ColumnName('earnings'), Comparator.ge, args.minimumEarnings)

	local opponentData

	if args.opponentType == Opponent.team then
		opponentData = StatisticsPortal._getTeams(queryLimit, tostring(earningsCondition), queryOrder)
	elseif args.opponentType == Opponent.solo then
		opponentData = StatisticsPortal._getPlayers(
			queryLimit,
			ConditionTree(BooleanOperator.all):add{
				earningsCondition,
				ConditionUtil.anyOf(
					ColumnName('nationality'),
					Array.map(Array.parseCommaSeparatedString(args.nationality), function (nationality)
						return Flags.CountryName{flag = nationality}
					end)
				)
			},
			queryOrder
		)
	end

	table.sort(opponentData, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	-- Only the displayed opponents are needed for the placement data
	local displayedOpponents = {}
	for opponentIndex, opponent in ipairs(opponentData) do
		if opponentIndex > args.limit or earningsFunction(opponent) < args.minimumEarnings then break end
		table.insert(displayedOpponents, opponent)
	end

	local opponentPlacements = StatisticsPortal._cacheOpponentPlacementData(args, displayedOpponents)

	local tableRow = {}
	for opponentIndex, opponent in ipairs(displayedOpponents) do
		local earnings = earningsFunction(opponent)

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
---@return ConditionTree
function StatisticsPortal._basePlacementConditions(args)
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

	return conditions:add{placementConditions}
end

---Queries the placements of the displayed opponents only, instead of all placements of the wiki.
---@param args table
---@param displayedOpponents table[]
---@return table
function StatisticsPortal._cacheOpponentPlacementData(args, displayedOpponents)
	if Logic.isEmpty(displayedOpponents) then
		return {}
	end

	local data = {}

	if args.opponentType == Opponent.team then
		local opponentConditions = ConditionTree(BooleanOperator.any)
		for _, team in ipairs(displayedOpponents) do
			opponentConditions:add{ConditionNode(ColumnName('opponentname'), Comparator.eq, team.pagename)}
			local spacedName = string.gsub(team.pagename, '_', ' ')
			if spacedName ~= team.pagename then
				opponentConditions:add{ConditionNode(ColumnName('opponentname'), Comparator.eq, spacedName)}
			end
		end

		StatisticsPortal._queryPlacements(
			args,
			StatisticsPortal._basePlacementConditions(args):add{opponentConditions},
			data
		)
		return data
	end

	-- A placement can have many players, so the conditions for a player are one per player slot.
	-- Query in batches to keep the conditions at a reasonable size.
	for firstIndex = 1, #displayedOpponents, PLAYER_BATCH_SIZE do
		local batch = Array.sub(displayedOpponents, firstIndex, firstIndex + PLAYER_BATCH_SIZE - 1)
		local isInBatch = {}
		local playerConditions = ConditionTree(BooleanOperator.any)

		for _, player in ipairs(batch) do
			isInBatch[player.pagename] = true
			local pageNames = {player.pagename}
			local spacedName = string.gsub(player.pagename, '_', ' ')
			if spacedName ~= player.pagename then
				table.insert(pageNames, spacedName)
			end
			for slot = 1, MAX_PLAYERS_PER_PLACEMENT do
				for _, pageName in ipairs(pageNames) do
					playerConditions:add{
						ConditionNode(ColumnName('opponentplayers_p' .. slot), Comparator.eq, pageName)
					}
				end
			end
		end

		-- Only credit the players of this batch, a placement of several players can show up in multiple batches
		StatisticsPortal._queryPlacements(
			args,
			StatisticsPortal._basePlacementConditions(args):add{playerConditions},
			data,
			isInBatch
		)
	end

	return data
end

---@param args table
---@param conditions ConditionTree
---@param data table
---@param opponentFilter table<string, boolean>?
function StatisticsPortal._queryPlacements(args, conditions, data, opponentFilter)
	local queryFields = 'pagename, shortname, icon, icondark, liquipediatier, liquipediatiertype, placement, '
	if args.opponentType == Opponent.solo then
		queryFields = queryFields .. 'opponentplayers, opponenttype'
	else
		-- opponentplayers is not needed for teams and is a large field
		queryFields = queryFields .. 'opponentname, opponenttype'
	end

	local queryParameters = {
		query = queryFields,
		conditions = conditions:toString(),
		limit = MAX_QUERY_LIMIT,
		order = 'date asc',
	}

	local function makeOpponentTable(item)
		local opponentNames = {}
		if args.opponentType == Opponent.solo then
			for _, playerName in Table.iter.pairsByPrefix(item.opponentplayers or {}, 'p') do
				local name = string.gsub(playerName or '', ' ', '_')
				if not opponentFilter or opponentFilter[name] then
					table.insert(opponentNames, name)
				end
			end
		elseif args.opponentType == Opponent.team and item.opponenttype == Opponent.team then
			local name = string.gsub(item.opponentname or '', ' ', '_')
			table.insert(opponentNames, name)
		end
		return opponentNames
	end

	local processData = function(item)
		local placement = string.sub(item.placement, 1, 1)
		for _, opponent in pairs(makeOpponentTable(item)) do
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
			TableWidgets.Cell{
				nowrap = false,
				children = StatisticsPortal._achievementsDisplay(placements.sWinData, args.maxAchievements)
			},
			TableWidgets.Cell{children = placements['1'] or '0'},
			TableWidgets.Cell{children = placements['2'] or '0'},
			TableWidgets.Cell{children = placements['3'] or '0'},
			Logic.readBool(args.displayShowMatches) and TableWidgets.Cell{children = placements.showWins or 0} or nil,
			TableWidgets.Cell{align = 'right', children = Currency.display(US_DOLLAR, earnings, CURRENCY_FORMAT_OPTIONS)}
		)
	}
end

---@param data table
---@param maxAchievements integer?
---@return string
function StatisticsPortal._achievementsDisplay(data, maxAchievements)
	if not data or #data == 0 then
		return ''
	end

	-- Placements are queried by ascending date, so when limiting show the most recent ones
	local firstIndex = maxAchievements and math.max(#data - maxAchievements + 1, 1) or 1

	-- Collect the parts and concatenate once, appending to a string per icon copies the whole string every time
	local output = {}
	for index = firstIndex, #data do
		local item = data[index]
		local icon = string.gsub(item.icon or '', 'File:', '')
		local iconDark = string.gsub(item.iconDark or '', 'File:', '')
		table.insert(output, LeagueIcon.display{
			icon = Logic.emptyOr(icon, 'Gold.png'),
			iconDark = iconDark,
			link = item.pagename,
			name = item.shortname,
			options = { noTemplate = true },
		})
		table.insert(output, ' ')
	end
	return table.concat(output)
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
