---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/WinRate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchWinRate : StandingsTiebreaker
local TiebreakerMatchWinRate = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWinRate:valueOf(state, opponent)
	local matchCount = opponent.match.w + opponent.match.l + opponent.match.d
	return matchCount ~= 0 and (opponent.match.w / matchCount) or 0.5
end

return TiebreakerMatchWinRate
