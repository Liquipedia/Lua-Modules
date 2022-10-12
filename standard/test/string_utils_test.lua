---
-- @Liquipedia
-- wiki=commons
-- page=Module:StringUtils/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local String = Lua.import('Module:StringUtils', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testStartsWith()
	self:assertFalse(String.startsWith('Cookie', 'banana'))
	self:assertFalse(String.startsWith('Banana', 'banana'))
	self:assertFalse(String.startsWith('Cookie & banana', 'banana'))
	self:assertTrue(String.startsWith('banana', 'banana'))
	self:assertTrue(String.startsWith('banana milkshake', 'banana'))
end

function suite:testEndsWith()
	self:assertFalse(String.endsWith('Cookie', 'banana'))
	self:assertFalse(String.endsWith('Banana', 'banana'))
	self:assertTrue(String.endsWith('Cookie & banana', 'banana'))
	self:assertTrue(String.endsWith('banana', 'banana'))
	self:assertFalse(String.endsWith('banana milkshake', 'banana'))
end

function suite:testSplit()
	self:assertDeepEquals({''}, String.split())
	self:assertDeepEquals({'hello', 'world'}, String.split('hello world'))
	self:assertDeepEquals({'he', 'owor', 'd'}, String.split('hello world', 'l'))
	self:assertDeepEquals({'he', 'oword'}, String.split('hello world', 'll'))
end

function suite:testTrim()
	self:assertEquals('', String.trim(''))
	self:assertEquals('hello world', String.trim('hello world'))
	self:assertEquals('hello world', String.trim(' hello world'))
	self:assertEquals('hello world', String.trim('hello world '))
	self:assertEquals('hello world', String.trim(' hello world '))
end

function suite:testNilIfEmpty()
	self:assertEquals(nil, String.nilIfEmpty(''))
	self:assertEquals(nil, String.nilIfEmpty())
	self:assertEquals(nil, String.nilIfEmpty(nil))
	self:assertEquals('hello world', String.nilIfEmpty('hello world'))
end

function suite:testIsEmpty()
	self:assertTrue(String.isEmpty(''))
	self:assertTrue(String.isEmpty())
	self:assertTrue(String.isEmpty(nil))
	self:assertFalse(String.isEmpty('hello world'))
end

function suite:testIsNotEmpty()
	self:assertFalse(String.isNotEmpty(''))
	self:assertFalse(String.isNotEmpty())
	self:assertFalse(String.isNotEmpty(nil))
	self:assertTrue(String.isNotEmpty('hello world'))
end

function suite:testInterpolate()
	self:assertEquals('', String.interpolate('', {}))
	self:assertEquals('I\'m 40 years old', String.interpolation('I\'m ${age} years old', {age = 40}))
end

return suite
