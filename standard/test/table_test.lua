---
-- @Liquipedia
-- wiki=commons
-- page=Module:Table/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
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
	self:assertTrue(Table.isNotEmpty({1,3,6}))
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

function suite:testMapArguments()
	local args = {a1a = 1, a3a = 3, a4a = 4, 2, 5}

	local function indexFromKey(key)
		local index = key:match('^a(%d+)a$')
		if index then
			return tonumber(index)
		else
			return nil
		end
	end

	local function mapFunction(key)
		return args[key] * 2
	end

	self:assertDeepEquals({2, 4, 6, 8, 10}, Table.mapArguments(args, indexFromKey, mapFunction))
	self:assertDeepEquals({2, [3] = 6, [4] = 8}, Table.mapArguments(args, indexFromKey, mapFunction, true))
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

function suite:testIncludes()
	local a = {'testValue', 'testValue2', 'testValue3'}
	local b = {key1 = 'testValue', key2 = 'testValue2', 'testValue3'}
	self:assertTrue(Table.includes(a, 'testValue'))
	self:assertTrue(Table.includes(b, 'testValue'))
	self:assertTrue(Table.includes(b, 'testValue3'))
	self:assertFalse(Table.includes(a, 'testValue4'))
	self:assertFalse(Table.includes(b, 'testValue4'))

	self:assertTrue(Table.includes(a, 'testValue', false))
	self:assertTrue(Table.includes(b, 'testValue', false))
	self:assertTrue(Table.includes({'^estValue3$'}, '^estValue3$', false))
	self:assertFalse(Table.includes(b, 'estValue', false))

	self:assertTrue(Table.includes(a, 'testValue', true))
	self:assertTrue(Table.includes(b, 'testValue', true))
	self:assertTrue(Table.includes(b, 'testValue3', true))
	self:assertTrue(Table.includes(b, 'estValue3', true))
	self:assertTrue(Table.includes(b, 'testValue%d', true))
	self:assertTrue(Table.includes(b, '^testValue%d$', true))
	self:assertFalse(Table.includes(b, '^estValue3$', true))
	self:assertFalse(Table.includes({'^estValue3$'}, '^estValue3$', true))
end

function suite:testFilterByKey()
	local a = {a1a = 1, a3a = 3, a4a = 4, 2, 5, b1b = 'ttt', c1c = 'ddd'}

	local function predicate1(key)
		return not Logic.isEmpty(string.find(key, '^%l(%d+)%l$'))
	end

	local function predicate2(key, value)
		return Logic.isNumeric(value) and not Logic.isEmpty(string.find(key, '^%l(%d+)%l$'))
	end

	self:assertDeepEquals({a1a = 1, a3a = 3, a4a = 4, b1b = 'ttt', c1c = 'ddd'}, Table.filterByKey(a, predicate1))
	self:assertDeepEquals({a1a = 1, a3a = 3, a4a = 4,}, Table.filterByKey(a, predicate2))
end

function suite:testPairsByPrefix()
	local args = {
		p = 'a',
		plink = 'b',
		f1 = 'a2',
		f1link = 'b2',
		p2 = 'c',
		p2link = 'd',
		p3 = 'e',
		p3link = 'f',
		foo = {},
		p10 = {},
	}

	local cnt = 0
	for prefix in Table.iter.pairsByPrefix(args, 'p', {requireIndex = false}) do
		cnt = cnt + 1
		self:assertTrue(args[prefix])
		self:assertTrue(args[prefix .. 'link'])
	end
	self:assertEquals(3, cnt)

	cnt = 0
	for prefix in Table.iter.pairsByPrefix(args, 'p') do
		cnt = cnt + 1
		self:assertTrue(args[prefix])
		self:assertTrue(args[prefix .. 'link'])
	end
	self:assertEquals(0, cnt)

	cnt = 0
	for prefix in Table.iter.pairsByPrefix(args, {'p', 'f'}) do
		cnt = cnt + 1
		self:assertTrue(args[prefix])
		self:assertTrue(args[prefix .. 'link'])
		if cnt == 1 then
			self:assertEquals('f1', prefix)
		else
			self:assertEquals('p' .. cnt, prefix)
		end
	end
	self:assertEquals(3, cnt)

	args.p1, args.p1link = args.p, args.plink
	args.p, args.plink = nil, nil

	cnt = 0
	for prefix in Table.iter.pairsByPrefix(args, 'p', {requireIndex = false}) do
		cnt = cnt + 1
		self:assertTrue(args[prefix])
		self:assertTrue(args[prefix .. 'link'])
	end
	self:assertEquals(3, cnt)

	cnt = 0
	for prefix in Table.iter.pairsByPrefix(args, 'p') do
		cnt = cnt + 1
		self:assertTrue(args[prefix])
		self:assertTrue(args[prefix .. 'link'])
	end
	self:assertEquals(3, cnt)
end

return suite
