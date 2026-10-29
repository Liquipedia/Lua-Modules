---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchScore = Lua.import('Module:Standings/Tiebreaker/Match/Score')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---Shares the column of TiebreakerMatchScore
---@class TiebreakerMatchLosses : TiebreakerMatchScore
local TiebreakerMatchLosses = Class.new(TiebreakerMatchScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchLosses:valueOf(state, opponent)
	return -TiebreakerMatchUtil.getMatches(opponent).l
end

return TiebreakerMatchLosses
