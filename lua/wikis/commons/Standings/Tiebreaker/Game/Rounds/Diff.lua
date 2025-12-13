---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Rounds/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerRoundDiff : StandingsTiebreaker
local TiebreakerRoundDiff = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundDiff:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return rounds.w - rounds.l
end

---@return string
function TiebreakerRoundDiff:headerTitle()
	return 'rounds'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerRoundDiff:display(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return rounds.w .. ' - ' .. rounds.l
end

return TiebreakerRoundDiff
