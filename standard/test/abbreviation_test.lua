---
-- @Liquipedia
-- wiki=commons
-- page=Module:Abbreviation/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Abbreviation = Lua.import('Module:Abbreviation', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testMakeAbbr()
	self:assertEquals(nil, Abbreviation.make())
	self:assertEquals(nil, Abbreviation.make(''))
	self:assertEquals('<abbr title="Cookie">Cake</abbr>', Abbreviation.make('Cake', 'Cookie'))
end

return suite
