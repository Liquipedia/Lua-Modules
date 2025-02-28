---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerPoints : StandingsTiebreaker
local TiebreakerPoints = Class.new(TiebreakerInteface)

---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerPoints:valueOf(opponent)
	return opponent.points
end

return TiebreakerPoints
