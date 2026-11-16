---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Regulation/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---Round difference with overtime maps counted as the narrowest regulation win
---@class TiebreakerRoundDiffRegulation : StandingsTiebreaker
local TiebreakerRoundDiffRegulation = Class.new(TiebreakerInterface)

TiebreakerRoundDiffRegulation.readsGames = true

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundDiffRegulation:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRegulationRounds(
		opponent, self.options.walkoverRounds, self.options.walkoverGames
	)
	return rounds.w - rounds.l
end

---@return string
function TiebreakerRoundDiffRegulation:headerTitle()
	return 'RD (R)'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundDiffRegulation:display(state, opponent)
	local diff = self:valueOf(state, opponent)
	return diff > 0 and ('+' .. diff) or tostring(diff)
end

return TiebreakerRoundDiffRegulation
