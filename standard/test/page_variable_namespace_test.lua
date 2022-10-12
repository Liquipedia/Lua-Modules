---
-- @Liquipedia
-- wiki=commons
-- page=Module:PageVariableNamespace/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local PVN = Lua.import('Module:PageVariableNamespace', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testGlobal()
	local global = PVN()
	global:set('foo', 'bar')
	global:set('alice', 'bob')
	self:assertEquals(nil, global:get('baz'))
	self:assertEquals('bar', global:get('foo'))
	self:assertEquals('bob', global:get('alice'))
	global:delete('foo')
	self:assertEquals(nil, global:get('foo'))
	self:assertEquals('bob', global:get('alice'))
	global:delete('alice')
	self:assertEquals(nil, global:get('foo'))
	self:assertEquals(nil, global:get('alice'))
end

function suite:testNS()
	local named = PVN('TestSpace')
	local global = PVN()
	named:set('foo', 'bar')
	named:set('alice', 'bob')
	self:assertEquals(nil, named:get('baz'))
	self:assertEquals('bar', named:get('foo'))
	self:assertEquals('bob', named:get('alice'))
	self:assertEquals(nil, global:get('foo'))
	named:delete('foo')
	self:assertEquals(nil, named:get('foo'))
	self:assertEquals('bob', named:get('alice'))
	named:delete('alice')
	self:assertEquals(nil, named:get('foo'))
	self:assertEquals(nil, named:get('alice'))
end

return suite
