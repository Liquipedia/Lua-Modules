---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchLosses : StandingsTiebreaker
local TiebreakerMatchLosses = Class.new(TiebreakerInteface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchLosses:valueOf(state, opponent)
	return - opponent.match.l
end

return TiebreakerMatchLosses
