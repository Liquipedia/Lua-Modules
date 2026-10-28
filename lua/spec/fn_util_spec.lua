--- Triple Comment to Enable our LLS Plugin
-- The specs run on plain Lua, where the garbage collector can be triggered
-- luacheck: read globals collectgarbage
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

		it('caches table inputs by identity', function()
			local calledCount = 0
			local wrap = FnUtil.memoize(function(x)
				calledCount = calledCount + 1
				return {x}
			end)
			local input = {}

			assert.are_equal(wrap(input), wrap(input))
			assert.are_equal(1, calledCount)
			assert.are_not_equal(wrap(input), wrap({}))
			assert.are_equal(2, calledCount)
		end)

		it('releases the result once the table input is garbage collected', function()
			-- The result must not reference the input, as that would keep the input alive
			local wrap = FnUtil.memoize(function(x) return {} end)
			local inputs = {input = {}}
			local results = setmetatable({}, {__mode = 'v'})
			-- Called from a function of its own, so no stack slot of the test keeps the input alive
			local function memoizeInput()
				results.result = wrap(inputs.input)
			end
			memoizeInput()

			collectgarbage('collect')
			assert.is_true(results.result ~= nil)
			inputs.input = nil
			-- Lua 5.1 drops the entry of a collected key in one cycle and frees its value in the next
			collectgarbage('collect')
			collectgarbage('collect')
			assert.is_true(results.result == nil)
		end)
	end)

	describe('memoize2', function()
		it('check', function()
			local calledCount = 0
			local multiply = FnUtil.memoize2(function(x, y)
				calledCount = calledCount + 1
				if x ~= nil and y ~= nil then
					return x * y
				end
				if x == nil and y == nil then
					return nil
				end
				return 0
			end)

			assert.are_equal(0, calledCount)
			assert.are_equal(4, multiply(2, 2))
			assert.are_equal(1, calledCount)
			assert.are_equal(4, multiply(2, 2))
			assert.are_equal(1, calledCount)
			assert.are_equal(9, multiply(3, 3))
			assert.are_equal(2, calledCount)
			assert.are_equal(9, multiply(3, 3))
			assert.are_equal(2, calledCount)
			assert.is_nil(multiply(nil, nil))
			assert.is_nil(multiply(nil, nil))
			assert.is_nil(multiply(nil, nil))
			assert.are_equal(3, calledCount)
			-- Mixed nil inputs are memoized independently
			assert.are_equal(0, multiply(2, nil))
			assert.are_equal(4, calledCount)
			assert.are_equal(0, multiply(2, nil))
			assert.are_equal(4, calledCount)
			assert.are_equal(0, multiply(nil, 3))
			assert.are_equal(5, calledCount)
			assert.are_equal(0, multiply(nil, 3))
			assert.are_equal(5, calledCount)
			-- Argument order produces separate cache entries
			assert.are_equal(6, multiply(2, 3))
			assert.are_equal(6, calledCount)
			assert.are_equal(6, multiply(3, 2))
			assert.are_equal(7, calledCount)
			assert.are_equal(6, multiply(2, 3))
			assert.are_equal(7, calledCount)
			assert.are_equal(6, multiply(3, 2))
			assert.are_equal(7, calledCount)
			-- Previously computed values remain cached after new computations
			assert.are_equal(4, multiply(2, 2))
			assert.are_equal(7, calledCount)
			assert.are_equal(9, multiply(3, 3))
			assert.are_equal(7, calledCount)
		end)

		it('releases the result once either table input is garbage collected', function()
			local pair = FnUtil.memoize2(function(x, y) return {} end)
			local inputs = {first = {}, second = {}, third = {}}
			local results = setmetatable({}, {__mode = 'v'})
			-- Called from a function of its own, so no stack slot of the test keeps the inputs alive
			local function memoizeInputs()
				results.firstGone = pair(inputs.first, 'y')
				results.secondGone = pair('x', inputs.second)
				results.kept = pair(inputs.third, 'y')
			end
			memoizeInputs()

			inputs.first, inputs.second = nil, nil
			-- Lua 5.1 drops the entry of a collected key in one cycle and frees its value in the next
			collectgarbage('collect')
			collectgarbage('collect')
			assert.is_true(results.firstGone == nil)
			assert.is_true(results.secondGone == nil)
			assert.is_true(results.kept ~= nil and results.kept == pair(inputs.third, 'y'))
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
