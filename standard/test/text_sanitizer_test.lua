---
-- @Liquipedia
-- wiki=commons
-- page=Module:TextSanitizer/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local TextSanitizer = Lua.import('Module:TextSanitizer', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testClass()
	self:assertEquals('Bar', TextSanitizer.stripHTML('<b class="foo">Bar</b>'))
	self:assertEquals('A -B', TextSanitizer.stripHTML('A&zwj;&nbsp;—B'))
	self:assertEquals('AB', TextSanitizer.stripHTML('A&shy;B'))
end

return suite
