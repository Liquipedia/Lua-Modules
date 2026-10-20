---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/SonnebornBerger
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local MathUtil = Lua.import('Module:MathUtil')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---Points of each faced opponent, weighted by the points gained in the match against them
---@class TiebreakerSonnebornBerger : StandingsTiebreaker
local TiebreakerSonnebornBerger = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerSonnebornBerger:valueOf(state, opponent)
	local isSelf = FnUtil.curry(Opponent.same, opponent.opponent)
	return MathUtil.sum(Array.map(opponent.matches, function(match)
		if not match.finished or #match.opponents ~= 2 then
			return 0
		end
		local enemy = Array.find(match.opponents, function(matchOpponent)
			return not isSelf(matchOpponent)
		end)
		---@cast enemy -nil
		local enemyMember = Array.find(state, function(member)
			return Opponent.same(member.opponent, enemy)
		end)
		-- Opponents outside of the standings have no points
		if not enemyMember then
			return 0
		end
		return ((opponent.matchPoints or {})[match.matchId] or 0) * enemyMember.points
	end))
end

---@return string
function TiebreakerSonnebornBerger:headerTitle()
	return 'Sonneborn-Berger'
end

return TiebreakerSonnebornBerger
