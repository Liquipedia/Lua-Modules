---
-- @Liquipedia
-- wiki=commons
-- page=Module:Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Count = {}

---Counts the number of matches played on a wiki - querying lpdb_match2
---@param args table?
---@return integer
function Count.match2(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	return Count._query('match2', lpdbConditions)
end


---Counts the number of matches played on a wiki - querying lpdb_match2game
---@param args table?
---@return integer
function Count.match2game(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)

	return Count._query('match2game', lpdbConditions)
end


---Counts the number of games played on a wiki - querying lpdb_match2
---@param args table?
---@return integer
function Count.match2gamesData(args)
	args = args or {}

	local data = {}

	local lpdbConditions = Count._baseConditions(args)

	local queryParameters = {
		query = 'match2games',
		conditions = lpdbConditions:toString(),
		limit = 1000,
	}

	local processFunction = function(item)
		if item.match2games then
			table.insert(data, item.match2games)
		end
	end

	Lpdb.executeMassQuery('match2', queryParameters, processFunction)

	return Table.size(Array.flatten(data))
end


---@deprecated `lpdb_game` is deprecated
---Counts the number of games played on a wiki
---@param args table?
---@return integer
function Count.games(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)

	return Count._query('game', lpdbConditions)
end


---@deprecated `lpdb_match` is deprecated
---Counts the number of matches played on a wiki
---@param args table?
---@return integer
function Count.matches(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	return Count._query('match', lpdbConditions)
end


---Counts the number of tournaments played on a wiki
---@param args table?
---@return integer
function Count.tournaments(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args, true)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	return Count._query('tournament', lpdbConditions)
end

---Counts the number of tournaments played on a wiki per tier/tiertype
---@param args table?
---@return table
function Count.tournamentsByTier(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args, true)

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = lpdbConditions:toString(),
		query = 'liquipediatier, liquipediatiertype, count::objectname',
		groupby = 'liquipediatier asc, liquipediatiertype asc'
	})

	return Table.mapValues(
		Table.groupBy(data, function(_, tbl) return Table.extract(tbl, 'liquipediatier') end),
		function(tierTable)
			return Table.map(
				tierTable,
				function(_, typeTable)
					return typeTable['liquipediatiertype'], typeTable['count_objectname']
				end
			)
		end
	)
end

---Counts the number of placements for a specified opponent on a wiki
---@param args table?
---@return integer
function Count.placements(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	if not Logic.readBool(args.includeShowmatch) then
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Showmatch')}
	end

	if not Logic.readBool(args.includeQualifier) then
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.neq, 'Qualifier')}
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier')}
	end

	if Logic.readBool(args.noEmptyPrizePool) then
		lpdbConditions:add{ConditionNode(ColumnName('prizemoney'), Comparator.neq, '')}
		lpdbConditions:add{ConditionNode(ColumnName('prizemoney'), Comparator.gt, 0)}
	end

	if String.isNotEmpty(args.player) then
		local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(args.player)
		local opponentWithUnderscores = opponent:gsub(' ', '_')
		local opponentConditions = ConditionTree(BooleanOperator.any)
		for index = 1, 10 do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_p' .. index), Comparator.eq, opponent),
				ConditionNode(ColumnName('opponentplayers_p' .. index), Comparator.eq, opponentWithUnderscores)
			}
		end
		lpdbConditions:add{opponentConditions}

	elseif String.isNotEmpty(args.team) then
		local opponentConditions = ConditionTree(BooleanOperator.any)
		Array.forEach(Count._getOpponentNames(args.team), function(templateValue)
			opponentConditions:add{
				ConditionNode(ColumnName('opponentname'), Comparator.eq, templateValue),
				ConditionNode(ColumnName('opponentname'), Comparator.eq, templateValue:gsub(' ', '_'))
			}
		end)
		lpdbConditions:add{opponentConditions}
	end

	if String.isNotEmpty(args.placement) then
		local placementConditions = ConditionTree(BooleanOperator.any)
		Array.forEach(Array.map(mw.text.split(args.placement, ',', true), String.trim),
			function(placementValue)
				placementConditions:add{ConditionNode(ColumnName('placement'), Comparator.eq, placementValue)}
			end
		)
		lpdbConditions:add{placementConditions}
	end

	return Count._query('placement', lpdbConditions)
end


---Returns the counted number based on the type of query
---@param queryType string
---@param lpdbConditions ConditionTree
---@return integer
function Count._query(queryType, lpdbConditions)
	local data = mw.ext.LiquipediaDB.lpdb(queryType, {
		conditions = lpdbConditions:toString(),
		query = 'count::objectname',
	})

	return tonumber(data[1]['count_objectname']) --[[@as integer]]
end


--[[
Condition Functions
]]--


---Retrieve all team templates for team argument parameter
---@param opponent string
---@return string[]
function Count._getOpponentNames(opponent)
	local opponentNames = TeamTemplate.queryHistoricalNames(opponent)
	return Array.extractValues(opponentNames)
end


---Returns the base query conditions based on input args
---@param args table
---@param isTournament boolean?
---@return ConditionTree
function Count._baseConditions(args, isTournament)
	args.sdate = args.sdate or args.startdate
	args.edate = args.edate or args.enddate

	local conditions = ConditionTree(BooleanOperator.all)

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	if args.type then
		conditions:add{ConditionNode(ColumnName('type'), Comparator.eq, args.type:lower())}
	end

	local startDateKey, endDateKey, sortDateKey
	if isTournament then
		startDateKey = 'startdate'
		endDateKey = 'enddate'
		sortDateKey = 'sortdate'

		if Logic.readBool(args.filterByStatus) then
			conditions:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
			conditions:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		end
	else
		startDateKey = 'date'
		endDateKey = 'date'
		sortDateKey = 'date'
	end

	if args.sdate then
		conditions:add{ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName(startDateKey), Comparator.gt, args.sdate),
			ConditionNode(ColumnName(startDateKey), Comparator.eq, args.sdate)
		}}
	end

	if args.edate then
		conditions:add{ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName(endDateKey), Comparator.lt, args.edate),
			ConditionNode(ColumnName(endDateKey), Comparator.eq, args.edate)
		}}
	end

	if args.year then
		conditions:add{ConditionNode(ColumnName(sortDateKey .. '_year'), Comparator.eq, args.year)}
	end

	return conditions
end

---Returns the query conditions related to tier based on input args
---@param args table
---@param lpdbConditions ConditionTree
---@return ConditionTree
function Count._tierConditions(args, lpdbConditions)
	args.liquipediatier = args.liquipediatier or args.tier

	if args.liquipediatier then
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.eq, args.liquipediatier)}
	end

	if args.publishertier then
		lpdbConditions:add{ConditionNode(ColumnName('publishertier'), Comparator.eq, args.publishertier)}
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.neq, 'Qualifier')}
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier')}
	end

	if args.liquipediatiertype then
		lpdbConditions:add{ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, args.liquipediatiertype)}
	end

	return lpdbConditions
end


return Class.export(Count)
