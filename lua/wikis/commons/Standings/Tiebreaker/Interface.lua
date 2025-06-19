---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Interface
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

---@alias TiebreakerOpponent {opponent: standardOpponent, points: number, matches: MatchGroupUtilMatch[],
---match: {w: integer, d: integer, l:integer}, extradata: table}

---@class StandingsTiebreaker
---@field context 'full'|'ml'|'h2h'
---@field valueOf fun(self, state:TiebreakerOpponent[], opponent: TiebreakerOpponent): integer
local StandingsTiebreaker = Class.new(function (self, context)
	self.context = context
end)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function StandingsTiebreaker:valueOf(state, opponent)
	error('This is an Interface')
end

---@return 'full'|'ml'|'h2h'
function StandingsTiebreaker:getContextType()
	return self.context
end

return StandingsTiebreaker
