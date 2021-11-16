---
-- @Liquipedia
-- wiki=commons
-- page=Module:MetadataGenerator/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MetadataGenerator = require('Module:MetadataGenerator')
local Arguments = require('Module:Arguments')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local suite = ScribuntoUnit:new()

local _EXPECTED_RESULT = 'Intel Extreme Masters XVI - Cologne is an offline German tournament organized by ESL.' ..
	' This [[Template:TierDisplay]] tournament took place from Jul 06 to Jul 18 2021 featuring 24 teams competing' ..
	' over a total prize pool of $1,000,000 USD.'

function suite:testGenerator()
	local args = Arguments.getArgs(mw.getCurrentFrame())
	self:assertEquals(_EXPECTED_RESULT, MetadataGenerator.tournament(args))
end

return suite
