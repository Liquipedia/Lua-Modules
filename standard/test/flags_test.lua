---
-- @Liquipedia
-- wiki=commons
-- page=Module:Flags/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})
local Data = mw.loadData('Module:Flags/MasterData')

local suite = ScribuntoUnit:new()

function suite:testIcon()
	local nlOutput = '<span class=\"flag\">[[File:nl_hd.png|Netherlands|link=]]</span>'
	local nlOutputLink = '<span class=\"flag\">[[File:nl_hd.png|Netherlands|link=Category:Netherlands]]</span>'
	self:assertEquals(nlOutput, Flags.Icon('nl'))
	self:assertEquals(nlOutput, Flags.Icon('nld'))
	self:assertEquals(nlOutput, Flags.Icon('holland'))
	self:assertEquals(nlOutput, Flags.Icon({}, 'nl'))
	self:assertEquals(nlOutput, Flags.Icon({}, 'nld'))
	self:assertEquals(nlOutput, Flags.Icon({}, 'holland'))
	self:assertEquals(nlOutputLink, Flags.Icon({shouldLink = true}, 'nl'))
	self:assertEquals(nlOutputLink, Flags.Icon({shouldLink = true}, 'nld'))
	self:assertEquals(nlOutputLink, Flags.Icon({shouldLink = true}, 'holland'))
	self:assertEquals(nlOutput, Flags.Icon({shouldLink = false}, 'nl'))
	self:assertEquals(nlOutput, Flags.Icon({shouldLink = false}, 'nld'))
	self:assertEquals(nlOutput, Flags.Icon({shouldLink = false}, 'holland'))
	self:assertEquals(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nl'})
	self:assertEquals(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nld'})
	self:assertEquals(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'holland'})
	self:assertEquals(nlOutput, Flags.Icon{shouldLink = false, flag = 'nl'})
	self:assertEquals(nlOutput, Flags.Icon{shouldLink = false, flag = 'nld'})
	self:assertEquals(nlOutput, Flags.Icon{shouldLink = false, flag = 'holland'})

	self:assertEquals('<span class=\"flag\">[[File:Space filler flag.png|link=]]</span>', Flags.Icon{flag = 'tbd'})

	self:assertEquals('[[Template:Flag/dummy]][[Category:Pages with unknown flags]]', Flags.Icon{shouldLink = true, flag = 'dummy'})
	self:assertEquals('[[Template:FlagNoLink/dummy]][[Category:Pages with unknown flags]]', Flags.Icon{shouldLink = false, flag = 'dummy'})
end

function suite:testLocalisation()
	local nlOutput = 'Dutch'
	self:assertEquals(nlOutput, Flags.getLocalisation('nl'))
	self:assertEquals(nlOutput, Flags.getLocalisation('Netherlands'))
	self:assertEquals(nlOutput, Flags.getLocalisation('netherlands'))
	self:assertEquals(nlOutput, Flags.getLocalisation('holland'))
end

function suite:testLanguageIcon()
	self:assertEquals('<span class=\"flag\">[[File:UsGb hd.png|English Speaking|link=]]</span>', Flags.languageIcon('en'))
	self:assertEquals('<span class=\"flag\">[[File:nl_hd.png|Netherlands|link=]]</span>', Flags.languageIcon('nl'))
end

function suite:testCountryName()
	local nlOutput = 'Netherlands'
	self:assertEquals(nlOutput, Flags.CountryName('nl'))
	self:assertEquals(nlOutput, Flags.CountryName('Netherlands'))
	self:assertEquals(nlOutput, Flags.CountryName('netherlands'))
	self:assertEquals(nlOutput, Flags.CountryName('holland'))
end

function suite:testCountryCode()
	local nlOutput = 'nl'
	self:assertEquals(nlOutput, Flags.CountryCode('nl'))
	self:assertEquals(nlOutput, Flags.CountryCode('Netherlands'))
	self:assertEquals(nlOutput, Flags.CountryCode('netherlands'))
	self:assertEquals(nlOutput, Flags.CountryCode('holland'))
end

return suite
