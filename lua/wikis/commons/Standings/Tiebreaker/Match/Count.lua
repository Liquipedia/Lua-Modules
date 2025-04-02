---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchCount : StandingsTiebreaker
local TiebreakerMatchCount = Class.new(TiebreakerInteface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchCount:valueOf(state, opponent)
	return opponent.match.w + opponent.match.l + opponent.match.d
end

return TiebreakerMatchCount
