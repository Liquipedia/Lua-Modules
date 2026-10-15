---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Buchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerBuchholz : StandingsTiebreaker
local TiebreakerBuchholz = Class.new(TiebreakerInterface)

---The score of a faced opponent
---@param member TiebreakerOpponent
---@return number
function TiebreakerBuchholz:scoreOf(member)
	return member.match.w - member.match.l
end

---Score of each distinct opponent faced in a finished match, in the order of the state
---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number[]
function TiebreakerBuchholz:opponentScores(state, opponent)
	local enemies = Array.flatMap(opponent.matches, function(match)
		if not match.finished then
			return {}
		end
		return Array.filter(match.opponents, function (opp)
			return not Opponent.same(opp, opponent.opponent)
		end)
	end)

	local enemyMembers = Array.filter(state, function(groupMember)
		return Array.any(enemies, function(enemy)
			return Opponent.same(enemy, groupMember.opponent)
		end)
	end)

	return Array.map(enemyMembers, function(member)
		return self:scoreOf(member)
	end)
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerBuchholz:valueOf(state, opponent)
	return MathUtil.sum(self:opponentScores(state, opponent))
end

---@return string
function TiebreakerBuchholz:headerTitle()
	return 'Buchholz'
end

return TiebreakerBuchholz
