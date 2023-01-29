---
-- @Liquipedia
-- wiki=commons
-- page=Module:Date/Ext/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local DateExt = Lua.import('Module:Date/Ext', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testReadTimestamp()
	self:assertEquals(1634506800, DateExt.readTimestamp('2021-10-17 17:40 <abbr data-tz="-4:00">EDT</abbr>'))
	self:assertEquals(1634506800, DateExt.readTimestamp('2021-10-17 21:40'))
end

function suite:testFormat()
	self:assertEquals('2021-10-17T21:40:00+00:00', DateExt.formatTimestamp('c', 1634506800))
end

function suite:testToYmdInUtc()
	self:assertEquals('2021-11-08', DateExt.toYmdInUtc('November 08, 2021 - 13:00 <abbr data-tz="+2:00">CET</abbr>'))
	self:assertEquals('2021-11-09', DateExt.toYmdInUtc('2021-11-08 17:00 <abbr data-tz="-8:00">PST</abbr>'))
end

return suite
