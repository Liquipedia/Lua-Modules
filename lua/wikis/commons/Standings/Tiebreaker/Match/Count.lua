---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---@class TiebreakerMatchCount : StandingsTiebreaker
local TiebreakerMatchCount = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchCount:valueOf(state, opponent)
	local matches = TiebreakerMatchUtil.getMatches(opponent)
	return matches.w + matches.l + matches.d
end

---@return string
function TiebreakerMatchCount:headerTitle()
	return 'Matches Played'
end

return TiebreakerMatchCount
