---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---The wins followed by the negated losses, shown as the match record
---@class TiebreakerMatchScore : StandingsTiebreaker
local TiebreakerMatchScore = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return StandingsTiebreakerValue
function TiebreakerMatchScore:valueOf(state, opponent)
	local matches = TiebreakerMatchUtil.getMatches(opponent)
	return {matches.w, -matches.l}
end

---@return string
function TiebreakerMatchScore:headerTitle()
	return 'Match'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerMatchScore:display(state, opponent)
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

return TiebreakerMatchScore
