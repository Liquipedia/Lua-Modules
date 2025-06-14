---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Draws
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerMatchDraws : StandingsTiebreaker
local TiebreakerMatchDraws = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDraws:valueOf(state, opponent)
	return opponent.match.d
end

return TiebreakerMatchDraws
