---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Interface
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

---@alias TiebreakerOpponent {opponent: standardOpponent, points: number, matches: MatchGroupUtilMatch[],
---matchPoints: table<string, number>?, match: {w: integer, d: integer, l:integer}, extradata: table,
---startingPoints: number?}

---@alias StandingsDrawLevel 'match'|'game'|'round'

---@class StandingsTiebreakerOptions
---@field draws table<StandingsDrawLevel, boolean>?

---@class StandingsTiebreaker
---@field context 'full'|'ml'|'h2h'|'h2hlegacy'
---@field options StandingsTiebreakerOptions
---@field valueOf fun(self: StandingsTiebreaker, state:TiebreakerOpponent[], opponent: TiebreakerOpponent): integer
---@field display fun(self: StandingsTiebreaker, state:TiebreakerOpponent[], opponent: TiebreakerOpponent): string
---@field headerTitle fun(self: StandingsTiebreaker): string
local StandingsTiebreaker = Class.new(function (self, context, options)
	self.context = context
	self.options = options or {}
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

---@return 'full'|'ml'|'h2h'|'h2hlegacy'
function StandingsTiebreaker:getContextType()
	return self.context
end

---@param level StandingsDrawLevel
---@return boolean
function StandingsTiebreaker:showsDraws(level)
	return (self.options.draws or {})[level] == true
end

return StandingsTiebreaker
