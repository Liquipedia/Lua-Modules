---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Regulation/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---Rounds won with overtime maps counted as the narrowest regulation win, shown as the regulation round record
---@class TiebreakerRoundWinsRegulation : StandingsTiebreaker
local TiebreakerRoundWinsRegulation = Class.new(TiebreakerInterface)

TiebreakerRoundWinsRegulation.readsGames = true

---@param opponent TiebreakerOpponent
---@return {rounds: integer, w: integer, l: integer}
function TiebreakerRoundWinsRegulation:getRounds(opponent)
	return TiebreakerRoundUtil.getRegulationRounds(opponent, self.options.walkoverRounds, self.options.walkoverGames)
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundWinsRegulation:valueOf(state, opponent)
	return self:getRounds(opponent).w
end

---@return string
function TiebreakerRoundWinsRegulation:headerTitle()
	return 'Round (R)'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundWinsRegulation:display(state, opponent)
	local rounds = self:getRounds(opponent)
	return rounds.w .. ' - ' .. rounds.l
end

return TiebreakerRoundWinsRegulation
