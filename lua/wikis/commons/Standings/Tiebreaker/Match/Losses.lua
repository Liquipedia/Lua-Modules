---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchDiff = Lua.import('Module:Standings/Tiebreaker/Match/Diff')

---Shares the column of TiebreakerMatchDiff
---@class TiebreakerMatchLosses : TiebreakerMatchDiff
local TiebreakerMatchLosses = Class.new(TiebreakerMatchDiff)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchLosses:valueOf(state, opponent)
	return -opponent.match.l
end

return TiebreakerMatchLosses
