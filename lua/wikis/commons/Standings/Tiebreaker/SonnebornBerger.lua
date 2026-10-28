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
		for _, matchOpponent in ipairs(match.opponents) do
			local member = TiebreakerMembers.find(state, matchOpponent)
			if member ~= selfMember then
				-- Opponents outside of the standings have no points
				return member and ((opponent.matchPoints or {})[match.matchId] or 0) * member.points or 0
			end
		end
		return 0
	end))
end

---@return string
function TiebreakerSonnebornBerger:headerTitle()
	return 'Sonneborn-Berger'
end

return TiebreakerSonnebornBerger
