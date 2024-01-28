--- Triple Comment to Enable our LLS Plugin
describe('LPDB Condition Builder', function()
	local Condition = require('Module:Condition')

	local ConditionTree = Condition.Tree
	local ConditionNode = Condition.Node
	local Comparator = Condition.Comparator
	local BooleanOperator = Condition.BooleanOperator
	local ColumnName = Condition.ColumnName

	it('build condition', function()
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

		tree:add()

		assert.are_equal(
			'[[date::<2020-03-02T00:00:00.000]] AND ([[opponent::Team Liquid]] OR [[opponent::Team Secret]]) ' ..
			'AND [[extradata_region::Europe]]',
			tree:toString()
		)
	end)
end)
