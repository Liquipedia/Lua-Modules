---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Buchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

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
	for _, match in ipairs(opponent.matches) do
		if match.finished then
			for _, matchOpponent in ipairs(match.opponents) do
				local member = TiebreakerMembers.find(state, matchOpponent)
				if member and member ~= selfMember then
					isFaced[member] = true
				end
			end
		end
	end

	local scores = {}
	for _, member in ipairs(state) do
		if isFaced[member] then
			table.insert(scores, self:scoreOf(member))
		end
	end
	return scores
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
