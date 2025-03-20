---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:ThisDay/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {1, 2},
	tierTypes = {'!Qualifier', '!Charity'},
	tierTypeBooleanOperator = require('Module:Condition').BooleanOperator.all,
}
