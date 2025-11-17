---
-- @Liquipedia
-- page=Module:Namespace/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Namespace = Lua.import('Module:Namespace')

local suite = ScribuntoUnit:new()

function suite:testIsMain()
	-- `Module:Namespace` treats Module talk space as main space
	self:assertEquals(true, Namespace.isMain())
end

function suite:testIdFromName()
	self:assertEquals(nil, Namespace.idFromName('bs'))
	self:assertEquals(nil, Namespace.idFromName())
	self:assertEquals(0, Namespace.idFromName(''))
	self:assertEquals(2, Namespace.idFromName('User'))
	self:assertEquals(4, Namespace.idFromName('Liquipedia'))
	self:assertEquals(136, Namespace.idFromName('Data'))
	self:assertEquals(829, Namespace.idFromName('Module talk'))
end

function suite:testNameFromId()
	self:assertEquals(nil, Namespace.nameFromId('bs'))
	self:assertEquals(nil, Namespace.nameFromId())
	self:assertEquals('', Namespace.nameFromId(0))
	self:assertEquals('', Namespace.nameFromId('0'))
	self:assertEquals('User', Namespace.nameFromId(2))
	self:assertEquals('User talk', Namespace.nameFromId(3))
	self:assertEquals('Liquipedia', Namespace.nameFromId('4'))
	self:assertEquals('Data', Namespace.nameFromId(136))
	self:assertEquals('Module talk', Namespace.nameFromId('829'))
end

function suite:testPrefixFromId()
	self:assertEquals(nil, Namespace.prefixFromId('bs'))
	self:assertEquals(nil, Namespace.prefixFromId())
	self:assertEquals('', Namespace.prefixFromId(0))
	self:assertEquals('', Namespace.prefixFromId('0'))
	self:assertEquals('User:', Namespace.prefixFromId(2))
	self:assertEquals('User talk:', Namespace.prefixFromId(3))
	self:assertEquals('Liquipedia:', Namespace.prefixFromId('4'))
	self:assertEquals('Data:', Namespace.prefixFromId(136))
	self:assertEquals('Module talk:', Namespace.prefixFromId('829'))
end

return suite
