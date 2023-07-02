---
-- @Liquipedia
-- wiki=commons
-- page=Module:FnUtil/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local FnUtil = Lua.import('Module:FnUtil', {requireDevIfEnabled = true})

local FnUtilTests = ScribuntoUnit:new()

function FnUtilTests:testMemoize()
	local calledCount = 0
	local square = FnUtil.memoize(function(x)
		calledCount = calledCount + 1
		return x ~= nil and x * x or nil
	end)

	self:assertEquals(0, calledCount)
	self:assertEquals(4, square(2))
	self:assertEquals(1, calledCount)
	self:assertEquals(4, square(2))
	self:assertEquals(1, calledCount)
	self:assertEquals(9, square(3))
	self:assertEquals(2, calledCount)
	self:assertEquals(9, square(3))
	self:assertEquals(2, calledCount)
	self:assertEquals(nil, square(nil))
	self:assertEquals(nil, square(nil))
	self:assertEquals(nil, square(nil))
	self:assertEquals(3, calledCount)
end

function FnUtilTests:testMemoizeY()
	local calledCount = 0
	local fibonacci = FnUtil.memoizeY(function(x, fibonacci)
		calledCount = calledCount + 1
		if x == 0 then return 0
		elseif x == 1 then return 1
		else return fibonacci(x - 1) + fibonacci(x - 2) end
	end)

	self:assertEquals(0, calledCount)
	self:assertEquals(8, fibonacci(6))
	self:assertEquals(7, calledCount)
	self:assertEquals(8, fibonacci(6))
	self:assertEquals(7, calledCount)
end

function FnUtilTests:testCurry()
	local add = function (a, b)
		return a + b
	end
	local add3 = FnUtil.curry(add, 3)

	self:assertEquals(8, add3(5))
end

return FnUtilTests
