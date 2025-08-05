---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerManual : StandingsTiebreaker
local TiebreakerManual = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerManual:valueOf(state, opponent)
	return opponent.extradata.tiebreakerpoints
end

return TiebreakerManual
