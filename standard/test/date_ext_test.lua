---
-- @Liquipedia
-- wiki=commons
-- page=Module:Date/Ext/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local Variables = require('Module:Variables')

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

function suite:testGetContextualDateOrNow()
	self:assertEquals(os.date('%F'), DateExt.getContextualDateOrNow())
	self:assertEquals(nil, DateExt.getContextualDate())

	Variables.varDefine('tournament_startdate', '2021-12-24')
	self:assertEquals('2021-12-24', DateExt.getContextualDateOrNow())
	self:assertEquals('2021-12-24', DateExt.getContextualDate())

	Variables.varDefine('tournament_enddate', '2021-12-28')
	self:assertEquals('2021-12-28', DateExt.getContextualDateOrNow())
	self:assertEquals('2021-12-28', DateExt.getContextualDate())

	Variables.varDefine('tournament_startdate')
	Variables.varDefine('tournament_enddate')
end

function suite:parseIsoDate()
	self:assertDeepEquals({year = 2023, month = 7, day = 24}, DateExt.parseIsoDate('2023-07-24'))
	self:assertDeepEquals({year = 2023, month = 7, day = 24}, DateExt.parseIsoDate('2023-07-24asdkosdkmoasjoikmakmslkm'))
	self:assertDeepEquals({year = 2023, month = 7, day = 1}, DateExt.parseIsoDate('2023-07'))
	self:assertDeepEquals({year = 2023, month = 7, day = 1}, DateExt.parseIsoDate('2023-07sdfsdfdfs'))
	self:assertDeepEquals({year = 2023, month = 1, day = 1}, DateExt.parseIsoDate('2023'))
	self:assertDeepEquals({year = 2023, month = 1, day = 1}, DateExt.parseIsoDate('202334rdfg'))
	self:assertEquals(nil, DateExt.parseIsoDate())
end

return suite
