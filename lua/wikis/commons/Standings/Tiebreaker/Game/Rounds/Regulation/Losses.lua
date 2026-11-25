---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Regulation/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundWinsRegulation = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Regulation/Wins')

---Shares the column of TiebreakerRoundWinsRegulation
---@class TiebreakerRoundLossesRegulation : TiebreakerRoundWinsRegulation
local TiebreakerRoundLossesRegulation = Class.new(TiebreakerRoundWinsRegulation)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundLossesRegulation:valueOf(state, opponent)
	return -self:getRounds(opponent).l
end

return TiebreakerRoundLossesRegulation
