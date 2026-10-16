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
	return 'Matches'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchDiff:display(state, opponent)
	-- With overtime, regulation and overtime results are shown separately. This takes priority over draws.
	if opponent.overtime then
		return table.concat({
			opponent.match.w, opponent.overtime.w, opponent.overtime.l, opponent.match.l
		}, ' - ')
	end
	if self:showsDraws('match') then
		return opponent.match.w .. ' - ' .. opponent.match.d .. ' - ' .. opponent.match.l
	end
	return opponent.match.w .. ' - ' .. opponent.match.l
end

return TiebreakerMatchDiff
