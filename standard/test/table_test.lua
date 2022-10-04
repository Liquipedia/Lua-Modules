---
-- @Liquipedia
-- wiki=commons
-- page=Module:Table/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Table = Lua.import('Module:Table', {requireDevIfEnabled = true})
local Data = mw.loadData('Module:Flags/MasterData')

local suite = ScribuntoUnit:new()

function suite:testSize()
	self:assertEquals(3, Table.size({1,3,6}))
	self:assertEquals(1, Table.size({1}))
	self:assertEquals(0, Table.size({}))
end

function suite:testIsEmpty()
	self:assertFalse(Table.isEmpty({1,3,6}))
	self:assertFalse(Table.isEmpty({1}))
	self:assertTrue(Table.isEmpty({}))
	self:assertTrue(Table.isEmpty())
	self:assertFalse(Table.isEmpty(Data))
end

function suite:testIsNotEmpty()
	self:assertTrue(true, Table.isNotEmpty({1,3,6}))
	self:assertTrue(Table.isNotEmpty({1}))
	self:assertFalse(Table.isNotEmpty({}))
	self:assertFalse(Table.isNotEmpty())
	self:assertTrue(Table.isNotEmpty(Data))
end

function suite:testCopy()
	local a, b, c = {1, 2, 3}, {}, {a = {}}
	self:assertDeepEquals(a, Table.copy(a))
	self:assertFalse(Table.copy(b) == b)
	self:assertTrue(Table.copy(c).a == c.a)
end

function suite:testDeep()
	local a, b, c = {1, 2, 3}, {}, {a = {}}
	self:assertTrue(Table.deepEquals(Table.deepCopy(a), a))
	self:assertTrue(Table.deepEquals(Table.deepCopy(b), b))
	self:assertFalse(Table.deepEquals(Table.deepCopy(b), a))
	self:assertFalse(Table.deepCopy(c).a == c.a)
end

function suite:testMerge()
	local a, b, c = {1, 2, 3}, {c = 5}, {a = 3}
	local d = Table.merge(a, b, c)
	local e = Table.mergeInto(a, b, c)
	self:assertFalse(a == d)
	self:assertTrue(a == e)
	self:assertDeepEquals({1, 2, 3, c = 5, a = 3}, d)
	self:assertDeepEquals({1, 2, 3, c = 5, a = 3}, e)
end

function suite:testDeepMerge()
	self:assertDeepEquals({a = {x = 3, y = 5}}, Table.deepMergeInto({a = {x = 3, y = 4}}, {a = {y = 5}}))
end

function suite:testMap()
	local a = {a = 3, b = 4, c = 5}
	self:assertDeepEquals({[6] = 'a', [8] = 'b', [10] = 'c'}, Table.map(a, function(k, v)
		return 2 * v, k
	end))
end

function suite:testMapValues()
	local a = {1, 2, 3}
	self:assertDeepEquals({2, 4, 6}, Table.mapValues(a, function(x)
		return 2 * x end
	))
end

function suite:testAll()
	local a = {1, 2, 3}
	self:assertTrue(Table.all(a, function (key, value)
		return key == value
	end))
	self:assertFalse(Table.all(a, function (key, value)
		return value < 3
	end))
end

function suite:testAny()
	local a = {1, 2, 3}
	self:assertFalse(Table.any(a, function (key, value)
		return type(value) == 'string'
	end))
	self:assertTrue(Table.any(a, function (key, value)
		return value < 3
	end))
end

function suite:testExtract()
	local a = {1, 2, 3}
	local b = Table.extract(a, 1)
	self:assertDeepEquals({[2] = 2, [3] = 3}, a)
	self:assertEquals(1, b)
end

return suite
