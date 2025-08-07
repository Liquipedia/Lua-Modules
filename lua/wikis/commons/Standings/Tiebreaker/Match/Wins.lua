---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchWins : StandingsTiebreaker
local TiebreakerMatchWins = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWins:valueOf(state, opponent)
	return opponent.match.w
end

---@return string
function TiebreakerMatchWins:headerTitle()
	return 'Matches Wins'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchWins:display(state, opponent)
	return tostring(self:valueOf(state, opponent))
end

return TiebreakerMatchWins
