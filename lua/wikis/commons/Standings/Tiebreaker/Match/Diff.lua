---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchDiff : StandingsTiebreaker
local TiebreakerMatchDiff = Class.new(TiebreakerInteface)

---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDiff:valueOf(state, opponent)
	return opponent.match.w - opponent.match.l
end

return TiebreakerMatchDiff
