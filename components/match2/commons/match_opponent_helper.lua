---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchOpponentHelper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')


local MatchOpponentHelper = {}

MatchOpponentHelper.STATUS = {
	SCORE = 'S',
	FORFEIT = 'FF',
	DISQUALIFIED = 'DQ',
	LOSS = 'L',
	WIN = 'W',
}

---@param opponents table[]
---@return string?
function MatchOpponentHelper.calculateWalkoverType(opponents)
	return (Array.find(opponents or {}, function(opponent)
		return opponent.status == MatchOpponentHelper.STATUS.FORFEIT
			or opponent.status == MatchOpponentHelper.STATUS.DISQUALIFIED
			or opponent.status == MatchOpponentHelper.STATUS.LOSS
	end) or {}).status
end



return MatchOpponentHelper
