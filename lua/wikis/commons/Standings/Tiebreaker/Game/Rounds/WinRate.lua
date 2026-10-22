---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/WinRate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerRoundWinRate : StandingsTiebreaker
local TiebreakerRoundWinRate = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerRoundWinRate:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return rounds.rounds == 0 and 0.5 or (rounds.w / rounds.rounds)
end

---@return string
function TiebreakerRoundWinRate:headerTitle()
	return 'Round Win %'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundWinRate:display(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	if rounds.rounds == 0 then
		return '-'
	end
	return MathUtil.formatPercentage(self:valueOf(state, opponent), 2)
end

return TiebreakerRoundWinRate
