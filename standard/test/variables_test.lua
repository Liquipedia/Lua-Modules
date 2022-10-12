---
-- @Liquipedia
-- wiki=commons
-- page=Module:Variables
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Variables = Lua.import('Module:Variables', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testVarDefine()
	self:assertEquals('', Variables.varDefine('test', 'foo'))
	self:assertEquals('foo', Variables.varDefault('test'))

	self:assertEquals('bar', Variables.varDefineEcho('test', 'bar'))
	self:assertEquals('bar', Variables.varDefault('test'))

	self:assertEquals('3', Variables.varDefine('test', 3))
	self:assertEquals('3', Variables.varDefault('test'))

	self:assertEquals('', Variables.varDefine('test'))
	self:assertEquals(nil, Variables.varDefault('test'))
end

function suite:testVarDefault()
	Variables.varDefine('test', 'foo')
	self:assertEquals('foo', Variables.varDefault('test'))
	self:assertEquals(nil, Variables.varDefault('bar'))
	self:assertEquals('baz', Variables.varDefault('bar', 'baz'))
end

function suite:testVarDefaultMulti()
	Variables.varDefine('baz', 'hello world')
	self:assertEquals('hello world', Variables.varDefaultMulti('foo', 'bar', 'baz'))
	self:assertEquals('banana', Variables.varDefaultMulti('foo', 'bar', 'banana'))
end

return suite
