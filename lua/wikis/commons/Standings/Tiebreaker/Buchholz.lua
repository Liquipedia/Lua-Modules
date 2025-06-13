---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Buchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

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

return TiebreakerBuchholz
