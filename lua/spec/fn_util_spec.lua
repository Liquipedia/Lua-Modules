--- Triple Comment to Enable our LLS Plugin
describe('function utils', function()
	local FnUtil = require('Module:FnUtil')

	describe('memoize', function()
		it('check', function()
			local calledCount = 0
			local square = FnUtil.memoize(function(x)
				calledCount = calledCount + 1
				return x ~= nil and x * x or nil
			end)

			assert.are_equal(0, calledCount)
			assert.are_equal(4, square(2))
			assert.are_equal(1, calledCount)
			assert.are_equal(4, square(2))
			assert.are_equal(1, calledCount)
			assert.are_equal(9, square(3))
			assert.are_equal(2, calledCount)
			assert.are_equal(9, square(3))
			assert.are_equal(2, calledCount)
			assert.is_nil(square(nil))
			assert.is_nil(square(nil))
			assert.is_nil(square(nil))
			assert.are_equal(3, calledCount)
		end)
	end)

	describe('memoize Y', function()
		it('check', function()
			local calledCount = 0
			local fibonacci = FnUtil.memoizeY(function(x, fibonacci)
				calledCount = calledCount + 1
				if x == 0 then
					return 0
				elseif x == 1 then
					return 1
				else
					return fibonacci(x - 1) + fibonacci(x - 2)
				end
			end)

			assert.are_equal(0, calledCount)
			assert.are_equal(8, fibonacci(6))
			assert.are_equal(7, calledCount)
			assert.are_equal(8, fibonacci(6))
			assert.are_equal(7, calledCount)
		end)
	end)

	describe('curry', function()
		it('check', function()
			local add = function(a, b)
				return a + b
			end
			local add3 = FnUtil.curry(add, 3)

			assert.are_equal(8, add3(5))
		end)
	end)
end)
