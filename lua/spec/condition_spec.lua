--- Triple Comment to Enable our LLS Plugin
describe('LPDB Condition Builder', function()
	local Condition = require('Module:Condition')

	local ConditionTree = Condition.Tree
	local ConditionNode = Condition.Node
	local Comparator = Condition.Comparator
	local BooleanOperator = Condition.BooleanOperator
	local ColumnName = Condition.ColumnName

	describe('test ConditionNode', function ()
		it('test basic comparator', function ()
			local conditionNode1 = ConditionNode(
				ColumnName('date'), Comparator.lessThan, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'[[date::<2020-03-02T00:00:00.000]]',
				conditionNode1:toString()
			)
		end)

		it('test ge', function ()
			local conditionNode2 = ConditionNode(
				ColumnName('date'), Comparator.greaterThanOrEqualTo, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'([[date::>2020-03-02T00:00:00.000]] OR [[date::2020-03-02T00:00:00.000]])',
				conditionNode2:toString()
			)
		end)

		it('test le', function ()
			local conditionNode3 = ConditionNode(
				ColumnName('date'), Comparator.lessThanOrEqualTo, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'([[date::<2020-03-02T00:00:00.000]] OR [[date::2020-03-02T00:00:00.000]])',
				conditionNode3:toString()
			)
		end)
	end)

	describe('build condition', function()
		it('without empty trees', function()
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
		it('with empty trees', function()
			local game1 = 'commons1'
			local game2 = 'commons2'

			local cond1 = ConditionTree(BooleanOperator.all):add{
				ConditionTree(BooleanOperator.all):add{},
				ConditionNode(ColumnName('game'), Comparator.eq, game1),
				ConditionTree(BooleanOperator.all)
			}
			local cond2 = ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('game'), Comparator.eq, game1),
				ConditionNode(ColumnName('game'), Comparator.eq, game2),
			}
			local cond3 = ConditionTree(BooleanOperator.all):add{
				ConditionTree(BooleanOperator.all):add{},
				cond2,
				ConditionTree(BooleanOperator.all),
			}
			local cond4 = ConditionTree(BooleanOperator.all):add{
				cond1,
				cond2,
				cond3,
			}
			local cond5 = ConditionTree(BooleanOperator.all):add{
				ConditionTree(BooleanOperator.all):add{ConditionTree(BooleanOperator.all):add{}},
				ConditionNode(ColumnName('game'), Comparator.eq, game1),
			}

			assert.are_equal(
				'[[game::commons1]]',
				cond1:toString()
			)
			assert.are_equal(
				'[[game::commons1]] OR [[game::commons2]]',
				cond2:toString()
			)
			assert.are_equal(
				'([[game::commons1]] OR [[game::commons2]])',
				cond3:toString()
			)
			assert.are_equal(
				'([[game::commons1]]) AND ([[game::commons1]] OR [[game::commons2]]) AND '..
					'(([[game::commons1]] OR [[game::commons2]]))',
				cond4:toString()
			)
			assert.are_equal(
				'[[game::commons1]]',
				cond5:toString()
			)
		end)
	end)
end)
