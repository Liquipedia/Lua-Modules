---
-- @Liquipedia
-- page=Module:ThisDay/Query
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Patch = Lua.import('Module:Patch')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local ConditionUtil = Condition.Util
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Config = Lua.import('Module:ThisDay/config', {loadData = true})

---Query operations for this day module
local ThisDayQuery = {}

--- Queries birthday data
---@param month integer
---@param day integer
---@return player[]
function ThisDayQuery.birthday(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('birthdate_month'), Comparator.eq, month),
			ConditionNode(ColumnName('birthdate_day'), Comparator.eq, day),
			ConditionNode(ColumnName('deathdate'), Comparator.eq, DateExt.defaultDate),
			ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate),
		}

	return mw.ext.LiquipediaDB.lpdb('player', {
		limit = 5000,
		conditions = conditions:toString(),
		query = 'extradata, pagename, id, birthdate, nationality, links',
		order = 'birthdate asc, id asc'
	})
end

--- Queries patch data
---@param month integer
---@param day integer
---@return StandardPatch[]
function ThisDayQuery.patch(month, day)
	local conditions = {
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
		ConditionNode(ColumnName('month', 'date'), Comparator.eq, month),
		ConditionNode(ColumnName('day', 'date'), Comparator.eq, day),
	}

	return Patch.queryPatches{
		limit = 5000,
		conditions = conditions,
		query = 'pagename, name, date',
		order = 'date asc, name asc'
	}
end

--- Queries tournament win data
---@param month integer
---@param day integer
---@return placement[]
function ThisDayQuery.tournament(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
			ConditionNode(ColumnName('date_month'), Comparator.eq, month),
			ConditionNode(ColumnName('date_day'), Comparator.eq, day),
			ConditionNode(ColumnName('date'), Comparator.lt, os.date('%Y-%m-%d', os.time() - 86400)),
			ConditionNode(ColumnName('placement'), Comparator.eq, 1),
			ConditionNode(ColumnName('opponentname'), Comparator.neq, 'TBD'),
			ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, '1'),
		}
	conditions:add(ConditionUtil.anyOf(
		ColumnName('liquipediatier'),
		Config.tiers
	))
	conditions:add(ConditionUtil.noneOf(
		ColumnName('liquipediatiertype'),
		Config.excludeTierTypes
	))

	return mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = conditions:toString(),
		query = 'extradata, pagename, date, icon, icondark, shortname, tournament, series, '
			.. 'opponentname, opponenttemplate, opponentplayers, opponenttype',
		order = 'date asc, pagename asc'
	})
end

return ThisDayQuery
