---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchDiff = Lua.import('Module:Standings/Tiebreaker/Match/Diff')

---Shares the column of TiebreakerMatchDiff
---@class TiebreakerMatchWins : TiebreakerMatchDiff
local TiebreakerMatchWins = Class.new(TiebreakerMatchDiff)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWins:valueOf(state, opponent)
	return opponent.match.w
end

return TiebreakerMatchWins
