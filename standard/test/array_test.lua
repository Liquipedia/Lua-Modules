---
-- @Liquipedia
-- wiki=commons
-- page=Module:Array/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Array = Lua.import('Module:Array', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testIsArray()
	self:assertTrue(Array.isArray{})
	self:assertTrue(Array.isArray{5, 2, 3})
	self:assertFalse(Array.isArray{a = 1, [3] = 2, c = 3})
	self:assertFalse(Array.isArray{5, 2, c = 3})
end

function suite:testCopy()
	local a, b, c = {1, 2, 3}, {}, {{5}}
	self:assertDeepEquals(a, Array.copy(a))
	self:assertFalse(Array.copy(b) == b)
	self:assertTrue(Array.copy(c)[1] == c[1])
end

function suite:testSub()
	local a = {3, 5, 7, 11}
	self:assertDeepEquals({5, 7, 11}, Array.sub(a, 2))
	self:assertDeepEquals({5, 7}, Array.sub(a, 2, 3))
	self:assertDeepEquals({7, 11}, Array.sub(a, -2, -1))
end

function suite:testMap()
	local a = {1, 2, 3}
	self:assertDeepEquals({2, 4, 6}, Array.map(a, function(x)
		return 2 * x
	end))
end

function suite:testFilter()
	local a = {1, 2, 3}
	self:assertDeepEquals({1, 3}, Array.filter(a, function(x)
		return x % 2 == 1 end
	))
end

function suite:testFlatten()
	local a = {1, 2, 3, {5, 3}, {6, 4}}
	self:assertDeepEquals({1, 2, 3, 5, 3, 6, 4}, Array.flatten(a))
end

function suite:testAll()
	local a = {1, 2, 3}
	self:assertTrue(Array.all(a, function (value)
		return type(value) == 'number'
	end))
	self:assertFalse(Array.all(a, function (value)
		return value < 3
	end))
end

function suite:testAny()
	local a = {1, 2, 3}
	self:assertFalse(Array.any(a, function (value)
		return type(value) == 'string'
	end))
	self:assertTrue(Array.any(a, function (value)
		return value < 3
	end))
end

function suite:testFind()
	local a = {4, 6, 9}
	local b = Array.find(a, function (value, index)
		return index == 2
	end)
	local c = Array.find(a, function (value, index)
		return index == -1
	end)
	self:assertEquals(6, b)
	self:assertEquals(nil, c)
end

function suite:testRevese()
	local a = {4, 6, 9}
	self:assertDeepEquals({9, 6, 4}, Array.reverse(a))
end

function suite:testAppend()
	local a = {2, 3}
	self:assertDeepEquals({2, 3, 5, 7, 11}, Array.append(a, 5, 7, 11))
	self:assertDeepEquals({2, 3}, a)
end

function suite:testAppendWith()
	local a = {2, 3}
	self:assertDeepEquals({2, 3, 5, 7, 11}, Array.appendWith(a, 5, 7, 11))
	self:assertDeepEquals({2, 3, 5, 7, 11}, a)
end

function suite:testExtend()
	local a, b, c = {2, 3}, {5, 7, 11}, {13}
	self:assertDeepEquals({2, 3, 5, 7, 11, 13}, Array.extend(a, b, c))
	self:assertDeepEquals({2, 3}, a)
end

function suite:testExtendWith()
	local a, b, c = {2, 3}, {5, 7, 11}, {13}
	self:assertDeepEquals({2, 3, 5, 7, 11, 13}, Array.extendWith(a, b, c))
	self:assertDeepEquals({2, 3, 5, 7, 11, 13}, a)
end

function suite:testMapIndexes()
	local a = {p1 = 'Abc', p2 = 'cd', p3 = 'cake'}
	self:assertDeepEquals({'p1Abc', 'p2cd'}, Array.mapIndexes(function(x)
		local prefix = 'p'.. x
		return a[prefix] ~= 'cake' and (prefix .. a[prefix]) or nil
	end))
end

function suite:testRange()
	self:assertDeepEquals({1, 2, 3}, Array.range(1, 3))
	self:assertDeepEquals({2, 3}, Array.range(2, 3))
end

function suite:testForEach()
	local a = {}
	Array.forEach(Array.range(1, 3), function(x)
		table.insert(a, 1, x)
	end)
	self:assertDeepEquals({3, 2, 1}, a)
end

function suite:testReduce()
	local function pow(x, y) return x ^ y end
	self:assertDeepEquals(32768, Array.reduce({2, 3, 5}, pow))
	self:assertDeepEquals(1, Array.reduce({2, 3, 5}, pow, 1))
end

function suite:testExtractValues()
	local a = {i = 1, j = 2, k = 3, z = 0}

	local customOrder1 = function(_, key1, key2) return key1 > key2 end
	local customOrder2 = function(tbl, key1, key2) return tbl[key1] < tbl[key2] end

	self:assertDeepEquals({1, 2, 3, 0}, Array.extractValues(a, Table.iter.spairs))
	self:assertDeepEquals({0, 3, 2, 1}, Array.extractValues(a, Table.iter.spairs, customOrder1))
	self:assertDeepEquals({0, 1, 2, 3}, Array.extractValues(a, Table.iter.spairs, customOrder2))

	local extractedArray = Array.extractValues(a)
	table.sort(extractedArray)
	self:assertDeepEquals({0, 1, 2, 3}, extractedArray)
end

function suite:testExtractKeys()
	local a = {k = 3, i = 1, z = 0, j = 2}

	local customOrder1 = function(_, key1, key2) return key1 > key2 end
	local customOrder2 = function(tbl, key1, key2) return tbl[key1] < tbl[key2] end

	self:assertDeepEquals({'i', 'j', 'k', 'z'}, Array.extractKeys(a, Table.iter.spairs))
	self:assertDeepEquals({'z', 'k', 'j', 'i'}, Array.extractKeys(a, Table.iter.spairs, customOrder1))
	self:assertDeepEquals({'z', 'i', 'j', 'k'}, Array.extractKeys(a, Table.iter.spairs, customOrder2))

	local extractedKeys = Array.extractKeys(a)
	table.sort(extractedKeys)
	self:assertDeepEquals({'i', 'j', 'k', 'z'}, extractedKeys)
end

return suite
