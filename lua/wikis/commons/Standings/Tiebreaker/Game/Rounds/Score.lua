---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---The wins followed by the negated losses, shown as the round record
---@class TiebreakerRoundScore : StandingsTiebreaker
local TiebreakerRoundScore = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return StandingsTiebreakerValue
function TiebreakerRoundScore:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(
		opponent, self.options.walkoverRounds, self.options.walkoverGames
	)
	return {rounds.w, -rounds.l}
end

---@return string
function TiebreakerRoundScore:headerTitle()
	return 'Round'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundScore:display(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(
		opponent, self.options.walkoverRounds, self.options.walkoverGames
	)
	return rounds.w .. ' - ' .. rounds.l
end

return TiebreakerRoundScore
