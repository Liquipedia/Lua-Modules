---
-- @Liquipedia
-- wiki=commons
-- page=Module:Class
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ReferenceCleaner = require('Module:ReferenceCleaner')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local suite = ScribuntoUnit:new()

function suite:testClass()
	self:assertEquals(ReferenceCleaner.clean('2021-07-05'), '2021-07-05')
	self:assertEquals(ReferenceCleaner.clean('2011-05-??'), '2011-05-01')
end

return suite
