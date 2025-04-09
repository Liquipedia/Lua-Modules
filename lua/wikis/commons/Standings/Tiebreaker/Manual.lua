---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TiebreakerInteface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerManual : StandingsTiebreaker
local TiebreakerManual = Class.new(TiebreakerInteface)

---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerManual:valueOf(state, opponent)
	return opponent.extradata.tiebreakerpoints
end

return TiebreakerManual
