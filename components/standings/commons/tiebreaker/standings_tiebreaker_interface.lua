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
---@field valueOf fun(self, opponent1: TiebreakerOpponent): integer
local StandingsTiebreaker = Class.new()

---@param opponent TiebreakerOpponent
---@return integer
function StandingsTiebreaker:valueOf(opponent)
	error('This is an Interface')
end

return StandingsTiebreaker
