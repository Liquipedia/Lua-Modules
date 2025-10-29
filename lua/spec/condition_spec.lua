--- Triple Comment to Enable our LLS Plugin
describe('LPDB Condition Builder', function()
	local Condition = require('Module:Condition')

	local ConditionTree = Condition.Tree
	local ConditionNode = Condition.Node
	local Comparator = Condition.Comparator
	local BooleanOperator = Condition.BooleanOperator
	local ColumnName = Condition.ColumnName
	local ConditionUtil = Condition.Util

	describe('test ConditionNode', function ()
		it('test basic comparator', function ()
			local conditionNode1 = ConditionNode(
				ColumnName('date'), Comparator.lessThan, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'[[date::<2020-03-02T00:00:00.000]]',
				conditionNode1:toString(),
				tostring(conditionNode1)
			)
		end)

		it('test ge', function ()
			local conditionNode2 = ConditionNode(
				ColumnName('date'), Comparator.greaterThanOrEqualTo, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'([[date::>2020-03-02T00:00:00.000]] OR [[date::2020-03-02T00:00:00.000]])',
				conditionNode2:toString(),
				tostring(conditionNode2)
			)
		end)

		it('test le', function ()
			local conditionNode3 = ConditionNode(
				ColumnName('date'), Comparator.lessThanOrEqualTo, '2020-03-02T00:00:00.000'
			)
			assert.are_equal(
				'([[date::<2020-03-02T00:00:00.000]] OR [[date::2020-03-02T00:00:00.000]])',
				conditionNode3:toString(),
				tostring(conditionNode3)
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
				tree:toString(),
				tostring(tree)
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
				cond1:toString(),
				tostring(cond1)
			)
			assert.are_equal(
				'[[game::commons1]] OR [[game::commons2]]',
				cond2:toString(),
				tostring(cond2)
			)
			assert.are_equal(
				'([[game::commons1]] OR [[game::commons2]])',
				cond3:toString(),
				tostring(cond3)
			)
			assert.are_equal(
				'([[game::commons1]]) AND ([[game::commons1]] OR [[game::commons2]]) AND '..
					'(([[game::commons1]] OR [[game::commons2]]))',
				cond4:toString(),
				tostring(cond4)
			)
			assert.are_equal(
				'[[game::commons1]]',
				cond5:toString(),
				tostring(cond5)
			)
		end)
	end)

	describe('Condition utilities test', function ()
		it('anyOf', function ()
			local tierColumnName = ColumnName('liquipediatier')

			assert.is_nil(ConditionUtil.anyOf(tierColumnName, {}))

			assert.are_equal(
				'[[liquipediatier::1]] OR [[liquipediatier::2]]',
				tostring(ConditionUtil.anyOf(tierColumnName, {1, 2}))
			)

			assert.are_equal(
				'[[liquipediatier::1]] OR [[liquipediatier::2]] OR [[liquipediatier::3]]',
				tostring(ConditionUtil.anyOf(tierColumnName, {1, 2, 3}))
			)

			assert.are_equal(
				'[[liquipediatier::1]] OR [[liquipediatier::2]] OR [[liquipediatier::3]]',
				tostring(ConditionUtil.anyOf(tierColumnName, {1, 2, 3, 2}))
			)
		end)

		it('noneOf', function ()
			local tierTypeColumnName = ColumnName('liquipediatiertype')

			assert.is_nil(ConditionUtil.noneOf(tierTypeColumnName, {}))

			assert.are_equal(
				'[[liquipediatiertype::!Qualifier]] AND [[liquipediatiertype::!Misc]]',
				tostring(ConditionUtil.noneOf(tierTypeColumnName, {'Qualifier', 'Misc'}))
			)
		end)
	end)
end)
