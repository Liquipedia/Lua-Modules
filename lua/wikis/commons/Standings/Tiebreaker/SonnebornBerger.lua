---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/SonnebornBerger
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMembers = Lua.import('Module:Standings/Tiebreaker/Members')

---Points of each faced opponent, weighted by the points gained in the match against them
---@class TiebreakerSonnebornBerger : StandingsTiebreaker
local TiebreakerSonnebornBerger = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerSonnebornBerger:valueOf(state, opponent)
	local selfMember = TiebreakerMembers.find(state, opponent.opponent)
	return MathUtil.sum(Array.map(opponent.matches, function(match)
		if not match.finished or #match.opponents ~= 2 then
			return 0
		end
		local enemy = Array.find(match.opponents, function(matchOpponent)
			return TiebreakerMembers.find(state, matchOpponent) ~= selfMember
		end)
		local enemyMember = enemy and TiebreakerMembers.find(state, enemy)
		-- Opponents outside of the standings have no points
		if not enemyMember then
			return 0
		end
		return ((opponent.matchPoints or {})[match.matchId] or 0) * enemyMember.points
	end))
end

---@return string
function TiebreakerSonnebornBerger:headerTitle()
	return 'SB'
end

return TiebreakerSonnebornBerger
