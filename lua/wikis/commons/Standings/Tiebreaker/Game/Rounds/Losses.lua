---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerRoundDiff = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Diff')

---Shares the column of TiebreakerRoundDiff
---@class TiebreakerRoundLosses : TiebreakerRoundDiff
local TiebreakerRoundLosses = Class.new(TiebreakerRoundDiff)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundLosses:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return -rounds.l
end

return TiebreakerRoundLosses
