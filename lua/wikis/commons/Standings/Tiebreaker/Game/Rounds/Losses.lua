---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerRoundLosses : StandingsTiebreaker
local TiebreakerRoundLosses = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundLosses:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return -rounds.l
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundLosses:display(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return tostring(rounds.l)
end

---@return string
function TiebreakerRoundLosses:headerTitle()
	return 'Rounds Lost'
end

return TiebreakerRoundLosses
