---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Buchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerBuchholz : StandingsTiebreaker
local TiebreakerBuchholz = Class.new(TiebreakerInterface)

---Build a set of enemy names for an opponent, memoized per opponent entry table.
---Falls back to Opponent.same for renamed-team detection and aliases the result.
---@param opponent TiebreakerOpponent
---@return table<string, true>
local getEnemyNames = FnUtil.memoize(function(opponent)
	local ownName = Opponent.toName(opponent.opponent)
	local enemyNames = {}
	Array.forEach(opponent.matches, function(match)
		if not match.finished then
			return
		end
		Array.forEach(match.opponents, function(matchOpponent)
			local name = Opponent.toName(matchOpponent)
			-- Skip self: by name, or by Opponent.same for renamed-team edge cases
			if name == ownName then
				return
			end
			if matchOpponent.type == 'team' and Opponent.same(matchOpponent, opponent.opponent) then
				return
			end
			enemyNames[name] = true
		end)
	end)
	return enemyNames
end)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerBuchholz:valueOf(state, opponent)
	local enemyNames = getEnemyNames(opponent)

	return Array.reduce(state, function(score, groupMember)
		local memberName = Opponent.toName(groupMember.opponent)
		local isEnemy = enemyNames[memberName]

		-- Fallback for renamed teams: scan match opponents with Opponent.same
		if not isEnemy and groupMember.opponent.type == 'team' then
			local found = Array.any(opponent.matches, function(match)
				if not match.finished then
					return false
				end
				return Array.any(match.opponents, function(matchOpponent)
					return Opponent.same(matchOpponent, groupMember.opponent)
				end)
			end)
			if found then
				-- Alias so this cost is only paid once per group member
				enemyNames[memberName] = true
				isEnemy = true
			end
		end

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

return TiebreakerBuchholz
