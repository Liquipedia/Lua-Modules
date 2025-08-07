---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Buchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerBuchholz : StandingsTiebreaker
local TiebreakerBuchholz = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerBuchholz:valueOf(state, opponent)
	local enemies = Array.flatMap(opponent.matches, function(match)
		return Array.filter(match.opponents, function (opp)
			return not Opponent.same(opp, opponent.opponent)
		end)
	end)

	return Array.reduce(state, function(score, groupMember)
		local isEnemy = Array.any(enemies, function(enemy)
			return Opponent.same(enemy, groupMember.opponent)
		end)

		if not isEnemy then
			return score
		end

		return score + groupMember.match.w - groupMember.match.l
	end, 0)
end

---@return string
function TiebreakerBuchholz:headerTitle()
	return 'Buchholz'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerBuchholz:display(state, opponent)
	return tostring(self:valueOf(state, opponent))
end

return TiebreakerBuchholz
