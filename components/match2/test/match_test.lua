---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchStorage = require('Module:MatchStorage')
local MatchTestConfig = require('Module:Match/testcases/config')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local suite = ScribuntoUnit:new()

function suite:testSplitRecordsByType()
	self:assertDeepEquals(
		MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT, MatchStorage.splitRecordsByType(MatchTestConfig.EXAMPLE_MATCH))
	self:assertDeepEquals(
		MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT_SC2, MatchStorage.splitRecordsByType(MatchTestConfig.EXAMPLE_MATCH_SC2))
	self:assertDeepEquals({}, MatchStorage.splitRecordsByType(nil))
	self:assertDeepEquals({}, MatchStorage.splitRecordsByType('something'))
end

return suite
