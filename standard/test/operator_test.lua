---
-- @Liquipedia
-- wiki=commons
-- page=Module:Operator/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Array = Lua.import('Module:Array', {requireDevIfEnabled = true})
local Operator = Lua.import('Module:Operator', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testMath()
	local foo = {5, 3, 2, 1}
	self:assertEquals(11, Array.reduce(foo, Operator.add), 'Add')
	self:assertEquals(-1, Array.reduce(foo, Operator.sub), 'Sub')
	self:assertEquals(30, Array.reduce(foo, Operator.mul), 'Mul')
	self:assertEquals(5/3/2, Array.reduce(foo, Operator.div), 'Div')
	self:assertEquals(15625, Array.reduce(foo, Operator.pow), 'Pow')
end

function suite:testEquality()
	local curry = function(f, x)
		return function(y)
			return f(x, y)
		end
	end
	local foo = {5, 3, 2, 1}
	self:assertDeepEquals({2}, Array.filter(foo, curry(Operator.eq, 2)), 'eq')
	self:assertDeepEquals({5, 3, 1}, Array.filter(foo, curry(Operator.neq, 2)), 'neq')
end

function suite:testProperty()
	local foo = {
		{a = 3, b = 'abc'},
		{a = 5, b = 'cedf'},
		{a = 4, b = 'sfd'},
	}
	self:assertDeepEquals({3, 5, 4}, Array.map(foo, Operator.property('a')))
end

function suite:testMethod()
	local foo = {
		{a = 3, b = 'abc', f = function(s, a)
			return s.a + a
		end},
		{a = 5, b = 'cedf', f = function(s)
			return s.a + 5
		end},
		{a = 4, b = 'sfd', f = function(s)
			return s.a + 3
		end},
	}
	self:assertDeepEquals({4, 10, 7}, Array.map(foo, Operator.method('f', 1)))
end

return suite
