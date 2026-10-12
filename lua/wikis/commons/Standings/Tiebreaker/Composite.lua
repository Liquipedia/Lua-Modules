---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Composite
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---A tiebreaker made of several tiebreakers that are compared in order (lexicographically),
---all evaluated on the same state. It is shown in the column of its first tiebreaker.
---@class TiebreakerComposite : StandingsTiebreaker
---@field tiebreakers StandingsTiebreaker[]
local TiebreakerComposite = Class.new(TiebreakerInterface, function(self, context, options, tiebreakers)
	self.tiebreakers = tiebreakers
end)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number[]
function TiebreakerComposite:valueOf(state, opponent)
	return Array.map(self.tiebreakers, function(tiebreaker)
		return tiebreaker:valueOf(state, opponent)
	end)
end

---@return string?
function TiebreakerComposite:headerTitle()
	return self.tiebreakers[1]:headerTitle()
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerComposite:display(state, opponent)
	return self.tiebreakers[1]:display(state, opponent)
end

return TiebreakerComposite
