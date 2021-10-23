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
	self:assertDeepEquals(
		MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT, Match.splitRecordsByType(MatchTestConfig.EXAMPLE_MATCH))
	self:assertDeepEquals(
		MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT_SC2, Match.splitRecordsByType(MatchTestConfig.EXAMPLE_MATCH_SC2))
end

return suite
