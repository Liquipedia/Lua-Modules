---
-- @Liquipedia
-- wiki=commons
-- page=Module:Locale/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Locale = Lua.import('Module:Locale', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

local NON_BREAKING_SPACE = '&nbsp;'

function suite:testFormatLocation()
	self:assertEquals('', Locale.formatLocation{})
	self:assertEquals('abc,' .. NON_BREAKING_SPACE, Locale.formatLocation{city = 'abc'})
	self:assertEquals('Sweden', Locale.formatLocation{country = 'Sweden'})
	self:assertEquals('abc,'.. NON_BREAKING_SPACE .. 'Sweden', Locale.formatLocation{city = 'abc', country = 'Sweden'})
end

function suite:testLocations()
	local test1 = {venue = 'Abc', country1 = 'Sweden', country2='Europe'}
	local result1 = {country1 = "se", region2 = "Europe", venue1 ="Abc"}

	local test2 = {venue = 'Abc', country1 = 'Sweden', region1='Europe', venuelink = 'https://lmgtfy.app/'}
	local result2 = {country1 = "se", region1 = "Europe", venue1 ="Abc", venuelink1 = 'https://lmgtfy.app/'}

	self:assertDeepEquals(result1, Locale.formatLocations(test1))
	self:assertDeepEquals(result2, Locale.formatLocations(test2))
	self:assertDeepEquals({}, Locale.formatLocations{dummy = true})
end

return suite
