---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Draws
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchDiff = Lua.import('Module:Standings/Tiebreaker/Match/Diff')

---Shares the column of TiebreakerMatchDiff
---@class TiebreakerMatchDraws : TiebreakerMatchDiff
local TiebreakerMatchDraws = Class.new(TiebreakerMatchDiff)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDraws:valueOf(state, opponent)
	return opponent.match.d
end

return TiebreakerMatchDraws
