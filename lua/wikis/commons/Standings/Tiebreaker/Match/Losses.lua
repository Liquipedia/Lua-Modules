---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchLosses : StandingsTiebreaker
local TiebreakerMatchLosses = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchLosses:valueOf(state, opponent)
	return -opponent.match.l
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchLosses:display(state, opponent)
	return tostring(opponent.match.l)
end

---@return string
function TiebreakerMatchLosses:headerTitle()
	return 'Matches Lost'
end

return TiebreakerMatchLosses
