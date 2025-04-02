---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchWins : StandingsTiebreaker
local TiebreakerMatchWins = Class.new(TiebreakerInteface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWins:valueOf(state, opponent)
	return opponent.match.w
end

return TiebreakerMatchWins
