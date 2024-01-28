--- Triple Comment to Enable our LLS Plugin
describe('operator', function()
	local Array = require('Module:Array')
	local Operator = require('Module:Operator')

	describe('math', function()
		it('check', function()
			local foo = {5, 3, 2, 1}
			assert.are_equal(11, Array.reduce(foo, Operator.add), 'Add')
			assert.are_equal(-1, Array.reduce(foo, Operator.sub), 'Sub')
			assert.are_equal(30, Array.reduce(foo, Operator.mul), 'Mul')
			assert.are_equal(5 / 3 / 2, Array.reduce(foo, Operator.div), 'Div')
			assert.are_equal(15625, Array.reduce(foo, Operator.pow), 'Pow')
		end)
	end)

	describe('equality', function()
		it('check', function()
			local curry = function(f, x)
				return function(y)
					return f(x, y)
				end
			end
			local foo = {5, 3, 2, 1}
			assert.are_same({2}, Array.filter(foo, curry(Operator.eq, 2)), 'eq')
			assert.are_same({5, 3, 1}, Array.filter(foo, curry(Operator.neq, 2)), 'neq')
		end)
	end)

	describe('property', function()
		it('check', function()
			local foo = {
				{a = 3, b = 'abc'},
				{a = 5, b = 'cedf'},
				{a = 4, b = 'sfd'},
			}
			assert.are_same({3, 5, 4}, Array.map(foo, Operator.property('a')))
		end)
	end)

	describe('method', function()
		it('check', function()
			local foo = {
				{
					a = 3,
					b = 'abc',
					f = function(s, a)
						return s.a + a
					end
				},
				{
					a = 5,
					b = 'cedf',
					f = function(s)
						return s.a + 5
					end
				},
				{
					a = 4,
					b = 'sfd',
					f = function(s)
						return s.a + 3
					end
				},
			}
			assert.are_same({4, 10, 7}, Array.map(foo, Operator.method('f', 1)))
		end)
	end)
end)
