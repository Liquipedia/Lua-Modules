---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Api/FetchPlacements
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local SeriesMedalStatisticsFetchPlacements = {}

---@param config SeriesMedalStatsConditionConfig
---@return placement[]
function SeriesMedalStatisticsFetchPlacements.run(config)
	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = SeriesMedalStatisticsFetchPlacements._getConditions(config),
		query = 'opponentplayers, placement, extradata, date, opponentname, opponenttype, opponenttemplate',
		order = 'date asc',
		limit = 5000,
	})
end

---@param config SeriesMedalStatsConditionConfig
---@return string
function SeriesMedalStatisticsFetchPlacements._getConditions(config)

	local endDate = config.endDate or DateExt.toYmdInUtc(DateExt.getCurrentTimestamp())

	local conditions = ConditionTree(BooleanOperator.all):add(Array.append({},
		ConditionUtil.anyOf(ColumnName('placement'), config.columns),
		ConditionUtil.anyOf(ColumnName('series'), config.series),
		ConditionUtil.anyOf(ColumnName('liquipediatier'), config.tier),
		ConditionUtil.anyOf(ColumnName('liquipediatiertype'), config.tierType),
		ConditionUtil.anyOf(ColumnName('opponenttype'), config.opponentTypes),
		ConditionNode(ColumnName('date'), Comparator.lt, endDate .. 'T23:59:59'),
		config.startDate and ConditionNode(ColumnName('date'), Comparator.ge, config.startDate) or nil
	))

	return tostring(conditions) .. config.additionalConditions
end

return SeriesMedalStatisticsFetchPlacements
