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
	self:assertEquals(Table.size({1,3,6}), 3)
	self:assertEquals(Table.size({1}), 1)
	self:assertEquals(Table.size({}), 0)
end

function suite:testIsEmpty()
	self:assertEquals(Table.isEmpty({1,3,6}), false)
	self:assertEquals(Table.isEmpty({1}), false)
	self:assertEquals(Table.isEmpty({}), true)
	self:assertEquals(Table.isEmpty(), true)
	self:assertEquals(Table.isEmpty(Data), false)
end

function suite:testIsNotEmpty()
	self:assertEquals(Table.isNotEmpty({1,3,6}), true)
	self:assertEquals(Table.isNotEmpty({1}), true)
	self:assertEquals(Table.isNotEmpty({}), false)
	self:assertEquals(Table.isNotEmpty(), false)
	self:assertEquals(Table.isNotEmpty(Data), true)
end

return suite
