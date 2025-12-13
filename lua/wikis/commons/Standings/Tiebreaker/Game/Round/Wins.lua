---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Round/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerRoundUtil = Lua.import('Module:Standings/Tiebreaker/Game/Round/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerRoundWins : StandingsTiebreaker
local TiebreakerRoundWins = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerRoundWins:valueOf(state, opponent)
	local rounds = TiebreakerRoundUtil.getRounds(opponent)
	return rounds.w
end

---@return string
function TiebreakerRoundWins:headerTitle()
	return 'Rounds Won'
end

return TiebreakerRoundWins
