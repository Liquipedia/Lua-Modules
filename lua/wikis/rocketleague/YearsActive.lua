---
-- @Liquipedia
-- page=Module:YearsActive
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Set = require('Module:Set')
local Table = require('Module:Table')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CustomActiveYears = Lua.import('Module:YearsActive/Base')

-- wiki specific settings
CustomActiveYears.defaultNumberOfStoredPlayersPerPlacement = 6
CustomActiveYears.additionalConditions = ''

-- legacy entry point
function CustomActiveYears.get(input)
	-- if invoked directly input == args
	-- if passed from modules it might be a table that holds the args table
	local args = input.args or input
	local display = CustomActiveYears.display(args)
	return display ~= CustomActiveYears.noResultsText and display or nil
end

function CustomActiveYears.getTalent(talent)
	return CustomActiveYears._getBroadcaster(
		CustomActiveYears._getBroadcastConditions(talent)
	)
end

function CustomActiveYears._getBroadcastConditions(broadcaster, positions)
	broadcaster = mw.ext.TeamLiquidIntegration.resolve_redirect(broadcaster):gsub(' ', '_')

	-- Add a condition for each broadcaster position
	local positionTree
	if positions then
		positionTree = ConditionTree(BooleanOperator.any)
		for _, position in pairs(positions) do
			positionTree:add(
				ConditionNode(ColumnName('position'), Comparator.eq, position)
			)
		end
	end

	local tree = ConditionTree(BooleanOperator.all):add({
		ConditionNode(ColumnName('page'), Comparator.eq, broadcaster),
		ConditionNode(ColumnName('date_year'), Comparator.gt, CustomActiveYears.startYear - 1),
		positionTree,
	})

	return tree:toString()
end

function CustomActiveYears._getBroadcaster(conditions)
	-- Get years
	local years = CustomActiveYears._getYearsBroadcast(conditions)
	if Table.isEmpty(years) then
		return
	end

	return CustomActiveYears.displayYears(years)
end

function CustomActiveYears._getYearsBroadcast(conditions)
	local years = Set{}
	local checkYear = function(broadcast)
		-- set the year in which the broadcast happened as true (i.e. active)
		local year = tonumber(string.sub(broadcast.date, 1, 4))
		years:add(year)
	end
	local queryParameters = {
		conditions = conditions,
		order = 'date asc',
		query = 'date',
	}
	Lpdb.executeMassQuery('broadcasters', queryParameters, checkYear)

	return years:toArray()
end

return Class.export(CustomActiveYears, {exports = {'get', 'getTalent', 'display'}})
