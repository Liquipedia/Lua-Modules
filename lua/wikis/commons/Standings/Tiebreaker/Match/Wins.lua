---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---@class TiebreakerMatchWins : StandingsTiebreaker
local TiebreakerMatchWins = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWins:valueOf(state, opponent)
	return TiebreakerMatchUtil.getMatches(opponent).w
end

---@return string
function TiebreakerMatchWins:headerTitle()
	return 'Matches Won'
end

return TiebreakerMatchWins
