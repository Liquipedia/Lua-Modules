---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

local HUGE_NUMBER = 1000000

---@class TiebreakerMatchScore : StandingsTiebreaker
local TiebreakerMatchScore = Class.new(TiebreakerInteface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchScore:valueOf(state, opponent)
	return (opponent.match.w * HUGE_NUMBER) - opponent.match.l
end

return TiebreakerMatchScore
