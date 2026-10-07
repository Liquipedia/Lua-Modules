---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Disqualified
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerDisqualified : StandingsTiebreaker
local TiebreakerDisqualified = Class.new(TiebreakerInterface)

---Disqualified opponents get the lowest value, and as tiebreakers sort descending they end up last.
---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerDisqualified:valueOf(state, opponent)
	return opponent.extradata.disqualified and 0 or 1
end

---@return string?
function TiebreakerDisqualified:headerTitle()
	return
end

return TiebreakerDisqualified
