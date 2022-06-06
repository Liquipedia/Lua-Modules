---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:CustomTournamentsSummaryTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomTournamentsSummaryTable = require('Module:TournamentsSummaryTable')

CustomTournamentsSummaryTable.tierTypeExcluded = {'Qualifier', 'Charity'}
CustomTournamentsSummaryTable.disableLIS = true
CustomTournamentsSummaryTable.defaultLimit = 7
local _SECONDS_PER_DAY = 86400
local _COMPLETED_OFFSET = 182 * _SECONDS_PER_DAY --roughly half a year

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

function CustomTournamentsSummaryTable.dateConditions(type)
	local conditions = ConditionTree(BooleanOperator.all)

	local currentTime = os.time()
	local today = os.date("!%Y-%m-%d", currentTime)
	local completedThreshold = os.date("!%Y-%m-%d", currentTime - _COMPLETED_OFFSET)

	if type == CustomTournamentsSummaryTable.upcomingType then
		conditions
			:add({ConditionNode(ColumnName('startdate'), Comparator.gt, today)})
	elseif type == CustomTournamentsSummaryTable.ongoingType then
		conditions
			:add({
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('startdate'), Comparator.lt, today),
					ConditionNode(ColumnName('startdate'), Comparator.eq, today),
				}),
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('enddate'), Comparator.gt, today),
					ConditionNode(ColumnName('enddate'), Comparator.eq, today),
				}),
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('extradata_winner'), Comparator.eq, 'TBD'),
					ConditionNode(ColumnName('extradata_winner'), Comparator.eq, 'tbd'),
					ConditionNode(ColumnName('enddate'), Comparator.gt, today),
				}),
			})
	elseif type == CustomTournamentsSummaryTable.recentType then
		conditions
			:add({
				ConditionNode(ColumnName('startdate'), Comparator.gt, completedThreshold),
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('enddate'), Comparator.lt, today),
					ConditionNode(ColumnName('enddate'), Comparator.eq, today),
				}),
				ConditionTree(BooleanOperator.any):add({
					ConditionTree(BooleanOperator.all):add({
						ConditionNode(ColumnName('enddate'), Comparator.lt, today),
						ConditionNode(ColumnName('extradata_winner'), Comparator.neq, 'TBD'),
						ConditionNode(ColumnName('extradata_winner'), Comparator.neq, 'tbd'),
					}),
					ConditionNode(ColumnName('enddate'), Comparator.gt, today),
				}),
			})
	end

	return conditions
end

return Class.export(CustomTournamentsSummaryTable)
