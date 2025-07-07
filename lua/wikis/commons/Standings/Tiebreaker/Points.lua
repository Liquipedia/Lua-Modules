---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Points
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerPoints : StandingsTiebreaker
local TiebreakerPoints = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerPoints:valueOf(state, opponent)
	return opponent.points
end

return TiebreakerPoints
