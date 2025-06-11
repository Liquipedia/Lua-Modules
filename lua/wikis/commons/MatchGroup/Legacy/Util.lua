---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')

local MatchLegacyUtil = {}

MatchLegacyUtil.STATUS = {
	SCORE = 'S',
	FORFEIT = 'FF',
	DISQUALIFIED = 'DQ',
	LOSS = 'L',
	WIN = 'W',
}

---@param opponents table[]
---@return string?
function MatchLegacyUtil.calculateWalkoverType(opponents)
	return (Array.find(opponents or {}, function(opponent)
		return opponent.status == MatchLegacyUtil.STATUS.FORFEIT
			or opponent.status == MatchLegacyUtil.STATUS.DISQUALIFIED
			or opponent.status == MatchLegacyUtil.STATUS.LOSS
	end) or {}).status
end

return MatchLegacyUtil
