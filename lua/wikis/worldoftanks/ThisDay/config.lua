---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:ThisDay/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Condition = require('Module:Condition')
local BooleanOperator = Condition.BooleanOperator

return {
	tiers = {1, 2},
	tierTypes = {'!Qualifier', '!Points', '!Showmatch'},
	tierTypeBooleanOperator = BooleanOperator.all,
	soloMode = 'individual',
}