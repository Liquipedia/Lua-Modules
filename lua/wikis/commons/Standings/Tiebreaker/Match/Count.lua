---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchCount : StandingsTiebreaker
local TiebreakerMatchCount = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchCount:valueOf(state, opponent)
	return opponent.match.w + opponent.match.l + opponent.match.d
end

---@return string
function TiebreakerMatchCount:headerTitle()
	return 'Matches Played'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchCount:display(state, opponent)
	return tostring(self:valueOf(state, opponent))
end

return TiebreakerMatchCount
