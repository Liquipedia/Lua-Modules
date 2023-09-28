---
-- @Liquipedia
-- wiki=commons
-- page=Module:Logic/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local Table = require('Module:Table')

local Logic = Lua.import('Module:Logic', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testEmptyOr()
	self:assertEquals(1, Logic.emptyOr(1, 2, 3))
	self:assertEquals(1, Logic.emptyOr(1, 2))
	self:assertEquals(1, Logic.emptyOr(1, nil, 3))
	self:assertEquals(1, Logic.emptyOr(1, '', 3))
	self:assertEquals(1, Logic.emptyOr(1))
	self:assertEquals(2, Logic.emptyOr(nil, 2, 3))
	self:assertEquals(2, Logic.emptyOr('', 2, 3))
	self:assertEquals(2, Logic.emptyOr(nil, 2))
	self:assertEquals(2, Logic.emptyOr('', 2))
	self:assertEquals(3, Logic.emptyOr(nil, nil, 3))
	self:assertEquals(3, Logic.emptyOr({}, '', 3))
	self:assertEquals(nil, Logic.emptyOr())
end

function suite:testNilOr()
	self:assertEquals(1, Logic.nilOr(1, 2, 3))
	self:assertEquals(1, Logic.nilOr(1, 2))
	self:assertEquals(1, Logic.nilOr(1, nil, 3))
	self:assertEquals(1, Logic.nilOr(1, '', 3))
	self:assertEquals(1, Logic.nilOr(1))
	self:assertEquals(2, Logic.nilOr(nil, 2, 3))
	self:assertEquals('', Logic.nilOr('', 2, 3))
	self:assertEquals(2, Logic.nilOr(nil, 2))
	self:assertEquals('', Logic.nilOr('', 2))
	self:assertEquals(3, Logic.nilOr(nil, nil, 3))
	self:assertDeepEquals({}, Logic.nilOr({}, '', 3))
	self:assertEquals(nil, Logic.nilOr())
	self:assertEquals(5, Logic.nilOr(nil, nil, nil, nil, 5))
end

function suite:testIsEmpty()
	self:assertTrue(Logic.isEmpty({}))
	self:assertTrue(Logic.isEmpty())
	self:assertTrue(Logic.isEmpty(''))
	self:assertFalse(Logic.isEmpty({''}))
	self:assertFalse(Logic.isEmpty({'string'}))
	self:assertFalse(Logic.isEmpty({{}}))
	self:assertFalse(Logic.isEmpty(1))
	self:assertFalse(Logic.isEmpty('string'))
end

function suite:testIsDeepEmpty()
	self:assertTrue(Logic.isDeepEmpty({}))
	self:assertTrue(Logic.isDeepEmpty())
	self:assertTrue(Logic.isDeepEmpty(''))
	self:assertTrue(Logic.isDeepEmpty({''}))
	self:assertFalse(Logic.isDeepEmpty({'string'}))
	self:assertTrue(Logic.isDeepEmpty({{}}))
	self:assertFalse(Logic.isDeepEmpty(1))
	self:assertFalse(Logic.isDeepEmpty('string'))
end

function suite:testReadBool()
	self:assertTrue(Logic.readBool(1))
	self:assertTrue(Logic.readBool('true'))
	self:assertTrue(Logic.readBool(true))
	self:assertTrue(Logic.readBool('t'))
	self:assertTrue(Logic.readBool('y'))
	self:assertTrue(Logic.readBool('yes'))
	self:assertTrue(Logic.readBool('1'))
	self:assertFalse(Logic.readBool(0))
	self:assertFalse(Logic.readBool(false))
	self:assertFalse(Logic.readBool('false'))
	self:assertFalse(Logic.readBool('f'))
	self:assertFalse(Logic.readBool('0'))
	self:assertFalse(Logic.readBool('no'))
	self:assertFalse(Logic.readBool('n'))
	self:assertFalse(Logic.readBool('someBs'))
	self:assertFalse(Logic.readBool())
	---intended bad value
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertFalse(Logic.readBool{})
end

function suite:testReadBoolOrNil()
	self:assertTrue(Logic.readBoolOrNil(1))
	self:assertTrue(Logic.readBoolOrNil('true'))
	self:assertTrue(Logic.readBoolOrNil(true))
	self:assertTrue(Logic.readBoolOrNil('t'))
	self:assertTrue(Logic.readBoolOrNil('y'))
	self:assertTrue(Logic.readBoolOrNil('yes'))
	self:assertTrue(Logic.readBoolOrNil('1'))
	self:assertFalse(Logic.readBoolOrNil(0))
	self:assertFalse(Logic.readBoolOrNil(false))
	self:assertFalse(Logic.readBoolOrNil('false'))
	self:assertFalse(Logic.readBoolOrNil('f'))
	self:assertFalse(Logic.readBoolOrNil('0'))
	self:assertFalse(Logic.readBoolOrNil('no'))
	self:assertFalse(Logic.readBoolOrNil('n'))
	self:assertEquals(nil, Logic.readBoolOrNil('someBs'))
	self:assertEquals(nil, Logic.readBoolOrNil())
	---intended bad value
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertEquals(nil, Logic.readBoolOrNil{})
end

function suite:testNilThrows()
	self:assertEquals('someVal', Logic.nilThrows('someVal'))
	self:assertEquals('', Logic.nilThrows(''))
	self:assertEquals(1, Logic.nilThrows(1))
	self:assertDeepEquals({'someVal'}, Logic.nilThrows({'someVal'}))
	self:assertDeepEquals({}, Logic.nilThrows({}))
	self:assertThrows(function() return Logic.nilThrows() end)
end

function suite:testTryCatch()
	local errorCaught = false
	local catch = function(errorMessage) errorCaught = true end

	self:assertEquals(nil, Logic.tryCatch(function() error() end, catch))
	self:assertTrue(errorCaught)
	errorCaught = false

	self:assertEquals(nil, Logic.tryCatch(function() error('some error') end, catch))
	self:assertTrue(errorCaught)
	errorCaught = false

	self:assertEquals(nil, Logic.tryCatch(function() assert(false, 'some failed assert') end, catch))
	self:assertTrue(errorCaught)
	errorCaught = false

	self:assertEquals('someVal', Logic.tryCatch(function() return 'someVal' end, catch))
	self:assertFalse(errorCaught)
end

function suite:testIsNumeric()
	self:assertTrue(Logic.isNumeric(1.5))
	self:assertTrue(Logic.isNumeric('1.5'))
	self:assertTrue(Logic.isNumeric('4.57e-3'))
	self:assertTrue(Logic.isNumeric(4.57e-3))
	self:assertTrue(Logic.isNumeric(0.3e12))
	self:assertTrue(Logic.isNumeric('0.3e12'))
	self:assertTrue(Logic.isNumeric(5e+20))
	self:assertTrue(Logic.isNumeric('5e+20'))
	self:assertFalse(Logic.isNumeric('1+2'))
	self:assertFalse(Logic.isNumeric())
	self:assertFalse(Logic.isNumeric('string'))
	---intended bad value
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertFalse(Logic.isNumeric{})
	---intended bad value
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertFalse(Logic.isNumeric{just = 'a table'})
end

function suite:testDeepEquals()
	self:assertTrue(Logic.deepEquals(1, 1))
	self:assertFalse(Logic.deepEquals(1, 2))
	self:assertTrue(Logic.deepEquals('a', 'a'))
	self:assertFalse(Logic.deepEquals('a', 'b'))

	local tbl1 = {1, 2, {3, 4, {a = 'b'}}}
	local tbl2 = {1, 2, {3, 4, {a = 'c'}}}
	local tbl3 = {1, 2, {3, 4, {a = 'b'}, 6}}
	self:assertTrue(Logic.deepEquals(tbl1, tbl1))
	self:assertTrue(Logic.deepEquals(tbl1, Table.deepCopy(tbl1)))
	self:assertFalse(Logic.deepEquals(tbl1, tbl2))
	self:assertFalse(Logic.deepEquals(tbl1, tbl3))
end

--currently not testing:
---try - just uses `Module:ResultOrError`
---tryOrElseLog - uses `.try` plus `:catch` and `:get`
---wrapTryOrLog - basically tryOrElseLog

return suite
