---
-- @Liquipedia
-- wiki=commons
-- page=Module:Region/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})
local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testName()
	self:assertEquals('', Region.name{region = ''})
	self:assertEquals('', Region.name{})
	self:assertEquals('', Region.name())
	self:assertEquals('Europe', Region.name{region = 'Europe'})
	self:assertEquals('South America', Region.name{region = 'sam'})
	self:assertEquals('Europe', Region.name{region = 'eu'})
end

function suite:testDisplay()
	local euFlag = Flags.Icon({flag = 'eu', shouldLink = true})
	self:assertEquals(euFlag .. '&nbsp;Europe', Region.display{region = 'Europe'})
	self:assertEquals('[[File:unasur.png]]&nbsp;South America', Region.display{region = 'sam'})
	self:assertEquals(euFlag .. '&nbsp;Europe', Region.display{region = 'eu'})
end

function suite:testRun()
	local euFlag = Flags.Icon({flag = 'eu', shouldLink = true})
	self:assertDeepEquals({display = euFlag .. '&nbsp;Europe', region = 'Europe'}, Region.run{region = 'Europe'})
	self:assertDeepEquals(
		{
			display = '[[File:unasur.png]]&nbsp;South America',
			region = 'South America'
		},
		Region.run{region = 'South America'}
	)
	self:assertDeepEquals({}, Region.run{})
	self:assertDeepEquals({}, Region.run{region = ''})
	self:assertDeepEquals({}, Region.run{country = ''})
end

return suite
