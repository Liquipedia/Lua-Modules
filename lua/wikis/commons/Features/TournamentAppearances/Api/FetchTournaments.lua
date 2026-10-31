---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Api/FetchTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local Page = Lua.import('Module:Page')
local Tournament = Lua.import('Module:Tournament')
local Table = Lua.import('Module:Table')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local FetchTournaments = {}

---@param config TournamentAppearancesConfig
---@return standardPlayer[]
function FetchTournaments.run(config)
	return Tournament.getAllTournaments(FetchTournaments._buildConditions(config))
end

---@param config TournamentAppearancesConfig
---@return ConditionTree|string
function FetchTournaments._buildConditions(config)
	if config.conditions then
		return config.conditions
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('enddate'), Comparator.gt, DateExt.defaultDate)}

	conditions:add(ConditionUtil.anyOf(ColumnName('status'), {'finished', ''}))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatier'), config.tiers))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatiertype'), config.tierTypes))

	if Table.isNotEmpty(config.series) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionUtil.anyOf(ColumnName(1, 'serieslist'), config.series),
			ConditionUtil.anyOf(ColumnName(2, 'serieslist'), config.series),
		})
	else
		conditions:add(ConditionUtil.anyOf(ColumnName('pagename'), Array.map(config.pages, Page.pageifyLink)))
	end

	if config.startDate then
		conditions:add(ConditionNode(ColumnName('startdate'), Comparator.ge, config.startDate))
	end

	if config.endDate then
		conditions:add(ConditionNode(ColumnName('enddate'), Comparator.le, config.endDate))
	end

	return conditions
end

return FetchTournaments
