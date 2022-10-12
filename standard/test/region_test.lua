---
-- @Liquipedia
-- wiki=commons
-- page=Module:Region/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Flag = Lua.import('Module:Flag', {requireDevIfEnabled = true})
local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testEmptyInput()
	self:assertEquals('', Region.run{})
	self:assertEquals('', Region.run{region = ''})
	self:assertEquals('', Region.run{country = ''})
end

function suite:testBasicResolving()
	self:assertEquals('Europe', Region.run{region = 'Europe', shouldOnlyReturnRegionName = true})
	self:assertEquals('South America', Region.run{region = 'sam', shouldOnlyReturnRegionName = true})
	self:assertEquals('Europe', Region.run{region = 'eu', shouldOnlyReturnRegionName = true})
end

function suite:testFullOutput()
	local euFlag = Flag.Icon({flag = 'eu', shouldLink = true})
	self:assertDeepEquals({display = euFlag .. '&nbsp;Europe', region = 'Europe'}, Region.run{region = 'Europe'})
	self:assertDeepEquals(
		{
			display = '[[File:unasur.png]]&nbsp;South America',
			region = 'South America'
		},
		Region.run{region = 'South America'}
	)
end

return suite
