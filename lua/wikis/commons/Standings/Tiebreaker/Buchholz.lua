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

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')
local TiebreakerMembers = Lua.import('Module:Standings/Tiebreaker/Members')

---@class TiebreakerBuchholz : StandingsTiebreaker
local TiebreakerBuchholz = Class.new(TiebreakerInterface)

---The score of a faced opponent
---@param member TiebreakerOpponent
---@return number
function TiebreakerBuchholz:scoreOf(member)
	local matches = TiebreakerMatchUtil.getMatches(member)
	return matches.w - matches.l
end

---Score of each distinct opponent faced in a finished match, in the order of the state
---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number[]
function TiebreakerBuchholz:opponentScores(state, opponent)
	local selfMember = TiebreakerMembers.find(state, opponent.opponent)
	---@type table<TiebreakerOpponent, true>
	local isFaced = {}
	Array.forEach(opponent.matches, function(match)
		if not match.finished then
			return
		end
		Array.forEach(match.opponents, function(matchOpponent)
			local member = TiebreakerMembers.find(state, matchOpponent)
			if not member or member == selfMember then
				return
			end
			isFaced[member] = true
		end)
	end)

	local facedMembers = Array.filter(state, function(member)
		return isFaced[member] == true
	end)
	return Array.map(facedMembers, function(member)
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
	return 'BH'
end

return TiebreakerBuchholz
