---
-- @Liquipedia
-- page=Module:Lua/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local LuaBasic = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local FeatureFlag = LuaBasic.import('Module:FeatureFlag')
local Lua = LuaBasic.import('Module:Lua')

local suite = ScribuntoUnit:new()

function suite:testModuleExists()
	self:assertFalse(Lua.moduleExists('Module:ThisLinkIsDead'))
	self:assertTrue(Lua.moduleExists('Module:Lua'))
	self:assertTrue(Lua.moduleExists('Module:Lua/dev'))
end

function suite:testIfExists()
	local devFlag = FeatureFlag.get('dev')
	self:assertEquals(nil, Lua.requireIfExists('Module:ThisLinkIsDead'))
	self:assertEquals(require('Module:Lua'), Lua.requireIfExists('Module:Lua'))
	FeatureFlag.set('dev', false)
	self:assertEquals(require('Module:Lua'), Lua.requireIfExists('Module:Lua'))
	FeatureFlag.set('dev', true)
	self:assertEquals(require('Module:Lua/dev'), Lua.requireIfExists('Module:Lua'))
	FeatureFlag.set('dev', devFlag)
end

function suite:testImport()
	local devFlag = FeatureFlag.get('dev')
	self:assertEquals(require('Module:Lua'), Lua.import('Module:Lua'))
	FeatureFlag.set('dev', false)
	self:assertEquals(require('Module:Lua'), Lua.import('Module:Lua'))
	FeatureFlag.set('dev', true)
	self:assertEquals(require('Module:Lua/dev'), Lua.import('Module:Lua'))
	FeatureFlag.set('dev', devFlag)
end

return suite
