---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchDiff : StandingsTiebreaker
local TiebreakerMatchDiff = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDiff:valueOf(state, opponent)
	return opponent.match.w - opponent.match.l
end

return TiebreakerMatchDiff
