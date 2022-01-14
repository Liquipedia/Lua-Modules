---
-- @Liquipedia
-- wiki=commons
-- page=Module:Condition/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Condition = require('Module:Condition')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local suite = ScribuntoUnit:new()

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

function suite:test()
	local tree = ConditionTree(BooleanOperator.all):add({
		ConditionNode(
			ColumnName('date'), Comparator.lessThan, '2020-03-02T00:00:00.000'
		),
		ConditionTree(BooleanOperator.any):add({
			ConditionNode(ColumnName('opponent'), Comparator.equals, 'Team Liquid'),
			ConditionNode(ColumnName('opponent'), Comparator.equals, 'Team Secret'),
		}),
		ConditionNode(
			ColumnName('region', 'extradata'), Comparator.equals, 'Europe'
		),
	})

	self:assertEquals(
		'[[date::<2020-03-02T00:00:00.000]] AND ([[opponent::Team Liquid]] OR [[opponent::Team Secret]]) ' ..
		'AND [[extradata_region::Europe]]',
		tree:toString()
	)
end

return suite
