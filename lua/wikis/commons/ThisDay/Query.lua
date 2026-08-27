---
-- @Liquipedia
-- page=Module:ThisDay/Query
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Opponent = Lua.import('Module:Opponent/Custom')
local Patch = Lua.import('Module:Patch')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local ConditionUtil = Condition.Util
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@type ThisDayConfig
local Config = Info.config.thisDay or {}

---@class (exact) ThisDayBirthdayRecord
---@field birthDate string
---@field player standardPlayer
---@field links table

---@class (exact) ThisDayTournamentWinRecord
---@field date string
---@field tournament StandardTournament
---@field opponent standardOpponent

local DEFAULT_TIERS = {1, 2}
local DEFAULT_EXCLUDED_TIER_TYPES = {'Qualifier'}

---Query operations for this day module
local ThisDayQuery = {}

--- Queries birthday data
---@param month integer
---@param day integer
---@return ThisDayBirthdayRecord[]
function ThisDayQuery.birthday(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('birthdate_month'), Comparator.eq, month),
			ConditionNode(ColumnName('birthdate_day'), Comparator.eq, day),
			ConditionNode(ColumnName('deathdate'), Comparator.eq, DateExt.defaultDate),
			ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate),
		}

	---@type ThisDayBirthdayRecord[]
	local queriedData = {}

	Lpdb.executeMassQuery(
		'player',
		{
			limit = 5000,
			conditions = tostring(conditions),
			query = 'extradata, pagename, id, birthdate, nationality, links',
			order = 'birthdate asc, id asc',
		},
		function (record)
			table.insert(queriedData, {
				birthDate = record.birthdate,
				player = PlayerExt.fromLpdbPlayerRecord(record),
				links = record.links,
			})
		end
	)

	return queriedData
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
		additionalConditions = conditions,
		query = 'pagename, name, date',
		order = 'date asc, name asc'
	}
end

--- Queries tournament win data
---@param month integer
---@param day integer
---@return ThisDayTournamentWinRecord[]
function ThisDayQuery.tournament(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
			ConditionNode(ColumnName('date_month'), Comparator.eq, month),
			ConditionNode(ColumnName('date_day'), Comparator.eq, day),
			ConditionNode(ColumnName('date_year'), Comparator.lt, DateExt.getYearOf()),
			ConditionNode(ColumnName('placement'), Comparator.eq, 1),
			ConditionNode(ColumnName('opponentname'), Comparator.neq, 'TBD'),
			ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, '1'),
		}
	conditions:add(ConditionUtil.anyOf(
		ColumnName('liquipediatier'),
		Logic.nilOr(Config.tiers, DEFAULT_TIERS) --[[ @as integer[] ]]
	))
	conditions:add(ConditionUtil.noneOf(
		ColumnName('liquipediatiertype'),
		Logic.nilOr(Config.excludeTierTypes, DEFAULT_EXCLUDED_TIER_TYPES) --[[ @as string[] ]]
	))

	---@type ThisDayTournamentWinRecord[]
	local queriedData = {}

	Lpdb.executeMassQuery(
		'placement',
		{
			limit = 5000,
			conditions = tostring(conditions),
			query = 'parent, date, opponentname, opponenttemplate, '
				.. 'opponentplayers, opponenttype',
			order = 'date asc, parent asc',
		},
		function (record)
			table.insert(queriedData, {
				date = record.date,
				opponent = Opponent.fromLpdbStruct(record),
				tournament = Tournament.getTournament(record.parent),
			})
		end
	)

	return queriedData
end

return ThisDayQuery
