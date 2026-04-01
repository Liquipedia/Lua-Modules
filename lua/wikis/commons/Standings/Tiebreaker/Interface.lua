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
---@field valueOf fun(self: StandingsTiebreaker, state:TiebreakerOpponent[], opponent: TiebreakerOpponent): integer
---@field display fun(self: StandingsTiebreaker, state:TiebreakerOpponent[], opponent: TiebreakerOpponent): string
---@field headerTitle fun(self: StandingsTiebreaker): string
local StandingsTiebreaker = Class.new(function (self, context)
	self.context = context
end)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function StandingsTiebreaker:valueOf(state, opponent)
	error('This is an Interface')
end

---Return nil to surpress this view
---@return string?
function StandingsTiebreaker:headerTitle()
	error('This is an Interface')
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function StandingsTiebreaker:display(state, opponent)
	return tostring(self:valueOf(state, opponent))
end

---@return 'full'|'ml'|'h2h'
function StandingsTiebreaker:getContextType()
	return self.context
end

return StandingsTiebreaker
