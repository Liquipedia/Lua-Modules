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
	self:assert(nil, global:get('baz'))
	self:assert('bar', global:get('foo'))
	self:assert('bob', global:get('alice'))
	global:delete('foo')
	self:assert(nil, global:get('foo'))
	self:assert('bob', global:get('alice'))
	global:delete('alice')
	self:assert(nil, global:get('foo'))
	self:assert(nil, global:get('alice'))
end

function suite:testNS()
	local named = PVN('TestSpace')
	local global = PVN()
	named:set('foo', 'bar')
	named:set('alice', 'bob')
	self:assert(nil, named:get('baz'))
	self:assert('bar', named:get('foo'))
	self:assert('bob', named:get('alice'))
	self:assert(nil, global:get('foo'))
	named:delete('foo')
	self:assert(nil, named:get('foo'))
	self:assert('bob', named:get('alice'))
	named:delete('alice')
	self:assert(nil, named:get('foo'))
	self:assert(nil, named:get('alice'))
end

return suite
