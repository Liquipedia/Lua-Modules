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
---@field context 'full'|'minileague'|'headtohead'
---@field valueOf fun(self, state:table, opponent: TiebreakerOpponent): integer
local StandingsTiebreaker = Class.new(function (self, context)
	self.context = context
end)

---@param state table
---@param opponent TiebreakerOpponent
---@return integer
function StandingsTiebreaker:valueOf(state, opponent)
	error('This is an Interface')
end

---@return 'full'|'minileague'|'headtohead'
function StandingsTiebreaker:getContextType()
	return self.context
end

return StandingsTiebreaker
