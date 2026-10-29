---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerRoundScore = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Score')

---Shares the column of TiebreakerRoundScore
---@class TiebreakerRoundWins : TiebreakerRoundScore
local TiebreakerRoundWins = Class.new(TiebreakerRoundScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundWins:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(
		opponent, self.options.walkoverRounds, self.options.walkoverGames
	)
	return rounds.w
end

return TiebreakerRoundWins
