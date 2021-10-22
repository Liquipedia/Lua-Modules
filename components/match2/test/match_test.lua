---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Match = require('Module:Match')
local MatchTestConfig = require('Module:Match/testcases/config')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local suite = ScribuntoUnit:new()

function suite:testSplitRecordsByType()
	local result = Match.splitRecordsByType(MatchTestConfig.EXAMPLE_MATCH)
	self:assertDeepEquals(MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT, result)
	self:assertEquals({}, Match.splitRecordsByType(nil))
end

return suite
