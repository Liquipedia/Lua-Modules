---
-- @Liquipedia
-- wiki=commons
-- page=Module:ReferenceCleaner/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testClass()
	self:assertEquals('2021-07-05', ReferenceCleaner.clean('2021-07-05'))
	self:assertEquals('2011-05-01', ReferenceCleaner.clean('2011-05-??'))
	self:assertEquals('2011-01-05', ReferenceCleaner.clean('2011-??-05'))
end

return suite
