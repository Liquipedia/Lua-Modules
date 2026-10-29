---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerRoundScore = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Score')

---Shares the column of TiebreakerRoundScore
---@class TiebreakerRoundLosses : TiebreakerRoundScore
local TiebreakerRoundLosses = Class.new(TiebreakerRoundScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundLosses:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(
		opponent, self.options.walkoverRounds, self.options.walkoverGames
	)
	return -rounds.l
end

return TiebreakerRoundLosses
