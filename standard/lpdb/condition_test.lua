local Condition = require('Module:Condition')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local suite = ScribuntoUnit:new()

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

function suite:test()
	local tree = ConditionTree(BooleanOperator['and']):addAll({
		ConditionNode(
			ColumnName('date'), Comparator.lesserThan, '2020-03-02T00:00:00.000'
		),
		ConditionTree(BooleanOperator['or']):addAll({
			ConditionNode(ColumnName('opponent'), Comparator.equals, 'Team Liquid'),
			ConditionNode(ColumnName('opponent'), Comparator.equals, 'Team Secret'),
		}),
		ConditionNode(
			ColumnName('region', 'extradata'), Comparator.equals, 'Europe'
		),
	})

	self:assertEquals(
		'[[date::<2020-03-02T00:00:00.000]] AND ([[opponent::Team Liquid]] OR [[opponent::Team Secret]]) AND [[extradata_region::Europe]]',
		tree:toString()
	)
end

return suite
