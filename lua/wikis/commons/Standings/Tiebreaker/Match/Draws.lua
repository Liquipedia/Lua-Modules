---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Draws
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchDraws : StandingsTiebreaker
local TiebreakerMatchDraws = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDraws:valueOf(state, opponent)
	return opponent.match.d
end

---@return string
function TiebreakerMatchDraws:headerTitle()
	return 'Matches Draws'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchDraws:display(state, opponent)
	return tostring(self:valueOf(state, opponent))
end

return TiebreakerMatchDraws
