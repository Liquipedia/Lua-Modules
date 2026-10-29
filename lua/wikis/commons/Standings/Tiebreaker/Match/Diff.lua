---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---@class TiebreakerMatchDiff : StandingsTiebreaker
local TiebreakerMatchDiff = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDiff:valueOf(state, opponent)
	local matches = TiebreakerMatchUtil.getMatches(opponent)
	return matches.w - matches.l
end

---@return string
function TiebreakerMatchDiff:headerTitle()
	return 'MD'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchDiff:display(state, opponent)
	local diff = self:valueOf(state, opponent)
	return diff > 0 and ('+' .. diff) or tostring(diff)
end

return TiebreakerMatchDiff
