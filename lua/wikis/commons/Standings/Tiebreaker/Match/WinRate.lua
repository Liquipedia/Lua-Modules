---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/WinRate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---@class TiebreakerMatchWinRate : StandingsTiebreaker
local TiebreakerMatchWinRate = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWinRate:valueOf(state, opponent)
	local matches = TiebreakerMatchUtil.getMatches(opponent)
	local matchCount = matches.w + matches.l + matches.d
	return matchCount ~= 0 and (matches.w / matchCount) or 0.5
end

---@return string
function TiebreakerMatchWinRate:headerTitle()
	return 'Match Win %'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchWinRate:display(state, opponent)
	return MathUtil.formatPercentage(self:valueOf(state, opponent), 2)
end

return TiebreakerMatchWinRate
