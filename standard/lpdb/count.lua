---
-- @Liquipedia
-- wiki=commons
-- page=Module:Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Team = require('Module:Team')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Count = {}


function Count.games(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)

	return Count._query('game', lpdbConditions)
end

function Count.matches(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	return Count._query('match', lpdbConditions)
end

function Count.tournaments(args)
	args = args or {}

	local lpdbConditions = Count._baseConditions(args, true)
	lpdbConditions = Count._tierConditions(args, lpdbConditions)

	return Count._query('tournament', lpdbConditions)
end

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
		local teamConditions = ConditionTree(BooleanOperator.any)
		for index = 1, 10 do
			teamConditions:add{
				ConditionNode(ColumnName('opponentplayers_p' .. index), Comparator.eq, opponent),
				ConditionNode(ColumnName('opponentplayers_p' .. index), Comparator.eq, opponentWithUnderscores)
			}
		end
		lpdbConditions:add{teamConditions}
	end

	if String.isNotEmpty(args.team) then
		local opponent = Team.queryRaw(args.team).page
		lpdbConditions:add{ConditionNode(ColumnName('opponentname'), Comparator.eq, opponent)}
	end

	if String.isNotEmpty(args.placement) then
		local placementConditions = ConditionTree(BooleanOperator.any)
		Array.map(Array.map(mw.text.split(args.placement, ',', true), String.trim),
		function(placementValue)
			return placementConditions:add{
				ConditionNode(ColumnName('placement'), Comparator.eq, placementValue)}
			end)
		lpdbConditions:add{placementConditions}
	end

	return Count._query('placement', lpdbConditions)
end



function Count._query(queryType, lpdbConditions)

	local data = mw.ext.LiquipediaDB.lpdb(queryType, {
		conditions = lpdbConditions:toString(),
		query = 'count::objectname',
	})

	return tonumber(data[1]['count_objectname'])
end


--[[
Condition Functions
]]--


function Count._baseConditions(args, isTournament)
	args.sdate = args.sdate or args.startdate
	args.edate = args.edate or args.enddate

	local conditions = ConditionTree(BooleanOperator.all)

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	if args.type then
		conditions:add{ConditionNode(ColumnName('type'), Comparator.eq, args.type:lower())}
	end

	local startDateKey, endDateKey, sortDateKey
	if isTournament then
		startDateKey = 'startdate'
		endDateKey= 'enddate'
		sortDateKey= 'sortdate'
	else
		startDateKey = 'date'
		endDateKey = 'date'
		sortDateKey= 'date'
	end

	if args.sdate then
		conditions:add{ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName(startDateKey), Comparator.gt, args.sdate),
			ConditionNode(ColumnName(startDateKey), Comparator.eq, args.sdate)
			},
		}
	end

	if args.edate then
		conditions:add{ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName(endDateKey), Comparator.lt, args.edate),
			ConditionNode(ColumnName(endDateKey), Comparator.eq, args.edate)
			},
		}
	end

	if args.year then
		conditions:add{ConditionNode(ColumnName(sortDateKey .. '_year'), Comparator.eq, args.year)}
	end

	return conditions
end

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
