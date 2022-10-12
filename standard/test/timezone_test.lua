---
-- @Liquipedia
-- wiki=commons
-- page=Module:Timezone/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Timezone = Lua.import('Module:Timezone', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testGetString()
	self:assertEquals(
		'<abbr data-tz="+05:30" title="Indian Standard Time (UTC+5:30)">IST</abbr>',
		Timezone.getTimezoneString('IST')
	)
	self:assertEquals(
		'<abbr data-tz="+02:00" title="Central European Summer Time (UTC+2)">CEST</abbr>',
		Timezone.getTimezoneString('CEST')
	)
	self:assertEquals(
		nil,
		Timezone.getTimezoneString('DUMMY')
	)
end

function suite:testGetOffset()
	self:assertEquals(
		5 * 60 * 60 + 30 * 60,
		Timezone.getOffset('IST')
	)
	self:assertEquals(
		2 * 60 * 60,
		Timezone.getOffset('CEST')
	)
	self:assertEquals(
		nil,
		Timezone.getOffset('DUMMY')
	)
end

function suite:testGetTimezoneData()
	self:assertDeepEquals(
		{
			abbr = 'IST',
			name = 'Indian Standard Time',
			offset = {5, 30},
		},
		Timezone.getTimezoneData('IST')
	)
	self:assertDeepEquals(
		{
			abbr = 'CEST',
			name = 'Central European Summer Time',
			offset = {2, 0},
		},
		Timezone.getTimezoneData('CEST')
	)
	self:assertDeepEquals(
		{
			abbr = 'CEST',
			name = 'Central European Summer Time',
			offset = {2, 0},
		},
		Timezone.getTimezoneData('cest')
	)
	self:assertEquals(
		nil,
		Timezone.getTimezoneData('DUMMY')
	)
	self:assertEquals(
		nil,
		Timezone.getTimezoneData(nil)
	)
end

return suite
