---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Interface
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

---@alias TiebreakerOpponent {opponent: standardOpponent, points: number, extradata: table}

---@class StandingsTiebreaker
---@field state table # The state of the league
---@field valueOf fun(self, opponent: TiebreakerOpponent): integer
local StandingsTiebreaker = Class.new(function (self, state)
	self.state = state
end)

---@param opponent TiebreakerOpponent
---@return integer
function StandingsTiebreaker:valueOf(opponent)
	error('This is an Interface')
end

return StandingsTiebreaker
