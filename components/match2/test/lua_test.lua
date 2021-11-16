---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lua/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local suite = ScribuntoUnit:new()

function suite:testClass()
	self:assertEquals(require('Module:Lua/testcases'), suite)
end

Lua.autoInvokeEntryPoints(suite, 'Module:Lua/testcases', {'run'})

return suite
