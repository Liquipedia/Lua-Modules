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

---@class TiebreakerMatchWinRate : StandingsTiebreaker
local TiebreakerMatchWinRate = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWinRate:valueOf(state, opponent)
	local matchCount = opponent.match.w + opponent.match.l + opponent.match.d
	return matchCount ~= 0 and (opponent.match.w / matchCount) or 0.5
end

---@return string
function TiebreakerMatchWinRate:headerTitle()
	return 'Match Win %'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchWinRate:display(state, opponent)
	return string.format('%.2f', MathUtil.round(self:valueOf(state, opponent) * 100, 2)) .. '%'
end

return TiebreakerMatchWinRate
