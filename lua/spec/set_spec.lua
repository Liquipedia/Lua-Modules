--- Triple Comment to Enable our LLS Plugin
describe('array', function()
	local Set = require('Module:Set')

	describe('basic properties', function()
		it('set membership', function()
			local arr = {1, 2, 3}
			---@type Set<integer>
			local set = Set(arr)

			for _, i in ipairs(arr) do
				assert.is_true(set:contains(i))
			end
			assert.is_false(set:contains(math.pi))
		end)

		it('set equality', function()
			---@type Set<integer>
			local set1 = Set{1, 2, 3}
			---@type Set<integer>
			local set2 = Set{1, 2, 3}
			---@type Set<integer>
			local set3 = Set{2, 4, 6, 8}

			assert.is_true(set1:equals(set1))
			assert.is_true(set1:equals(set2))
			assert.is_false(set1:equals(set3))
		end)

		it('all elements are unique', function()
			---@type Set<integer>
			local set1 = Set{1, 2, 3}
			---@type Set<integer>
			local set2 = Set{1, 2, 3}

			set1:addAll(set2)

			assert.are_equal(3, set1:size())

			assert.are_same({1, 2, 3}, set1:toArray())
		end)
	end)

	describe('set operations', function()
		it('check set union', function()
			---@type Set<integer>
			local set1 = Set{1, 2, 3}
			---@type Set<integer>
			local set2 = Set{2, 4, 6, 8}

			local union1 = set1:union(set2)
			local union2 = set1 + set2

			assert.equal(6, union1:size())
			assert.equal(6, union2:size())

			assert.are_same({1, 2, 3, 4, 6, 8}, union1:toArray())
			assert.are_same({1, 2, 3, 4, 6, 8}, union2:toArray())
		end)

		it('check set intersection', function()
			---@type Set<integer>
			local set1 = Set{1, 2, 3}
			---@type Set<integer>
			local set2 = Set{2, 4, 6, 8}

			local intersection1 = set1:intersection(set2)
			local intersection2 = set1 - set2

			assert.is_false(intersection1:isEmpty())
			assert.is_false(intersection2:isEmpty())

			assert.are_same({2}, intersection1:toArray())
			assert.are_same({2}, intersection2:toArray())

			assert.is_true(intersection1 == intersection2)
		end)

		it('check set difference', function()
			---@type Set<integer>
			local set1 = Set{1, 2, 3}
			---@type Set<integer>
			local set2 = Set{2, 4, 6, 8}

			local diff = set1:difference(set2)

			assert.is_false(diff:isEmpty())

			assert.are_same({1, 3}, diff:toArray())
		end)
	end)
end)
