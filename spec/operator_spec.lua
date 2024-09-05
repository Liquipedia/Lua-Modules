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
		local foo = {
			{a = 3, b = 'abc'},
			{a = 5, b = 'cedf'},
			{a = 4, b = 'sfd'},
		}
		it('accesses single properties', function()
			assert.are_same({3, 5, 4}, Array.map(foo, Operator.property('a')))
			assert.is_nil( Operator.property(5)(foo))
		end)
		it('accesses properties on a given path', function()
			local bar = {
				{a = {b = {c = 'd1'}, e = 'f1', 's1'}, g = 'h1', 't1', ['5'] = 'q1'},
				{a = {b = {c = 'd2'}, e = 'f2', 's2'}, g = 'h2', 't2', ['5'] = 'q2'},
			}
			assert.are_same({{c = 'd1'}, {c = 'd2'}}, Array.map(bar, Operator.property('a.b')))
			assert.are_same({'d1', 'd2'}, Array.map(bar, Operator.property('a.b.c')))
			assert.are_same({'f1', 'f2'}, Array.map(bar, Operator.property('a.e')))
			assert.are_same({'s1', 's2'}, Array.map(bar, Operator.property('a.1')))
			assert.are_same({'t1', 't2'}, Array.map(bar, Operator.property(1)))
			assert.are_same({'t1', 't2'}, Array.map(bar, Operator.property('1')))
			assert.are_same({'q1', 'q2'}, Array.map(bar, Operator.property('5')))
			assert.are_same({'q1', 'q2'}, Array.map(bar, Operator.property(5)))
		end)
		it('throws if an accessed table is nil', function()
			assert.error(function() return Operator.property('a.1')(foo) end)
		end)
		it('throws if path input is of unsupported type', function()
			assert.error(Operator.property)
			-- intended type mismatch
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() Operator.property(foo) end)
			-- intended type mismatch
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() Operator.property(nil) end)
		end)
		it('throws if table input is of unsupported type', function()
			assert.error(Operator.property('a'))
			-- intended type mismatch
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() return Operator.property('a')('string') end)
			-- intended type mismatch
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() return Operator.property('a')(1) end)
			-- intended type mismatch
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() return Operator.property('a')(nil) end)
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
