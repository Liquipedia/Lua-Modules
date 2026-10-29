---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchScore = Lua.import('Module:Standings/Tiebreaker/Match/Score')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---Shares the column of TiebreakerMatchScore
---@class TiebreakerMatchCount : TiebreakerMatchScore
local TiebreakerMatchCount = Class.new(TiebreakerMatchScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchCount:valueOf(state, opponent)
	local matches = TiebreakerMatchUtil.getMatches(opponent)
	return matches.w + matches.l + matches.d
end

return TiebreakerMatchCount
