---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Members
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerMembers = {}

-- Comparing opponents can take team template lookups, and tiebreakers look up the same match opponents in every
-- round. All rounds share the standings opponents, so the standings opponent of a match opponent is remembered.
---@type table<standardOpponent, standardOpponent>
local standingsOpponentByMatchOpponent = setmetatable({}, {__mode = 'k'})
---@type table<TiebreakerOpponent[], table<standardOpponent, TiebreakerOpponent>>
local membersByState = setmetatable({}, {__mode = 'k'})

---Finds the member of the state (the opponents of a round) that a match opponent is.
---@param state TiebreakerOpponent[]
---@param matchOpponent standardOpponent
---@return TiebreakerOpponent?
function TiebreakerMembers.find(state, matchOpponent)
	local membersByOpponent = membersByState[state]
	if not membersByOpponent then
		membersByOpponent = {}
		for _, member in ipairs(state) do
			membersByOpponent[member.opponent] = member
		end
		membersByState[state] = membersByOpponent
	end

	local standingsOpponent = standingsOpponentByMatchOpponent[matchOpponent]
	if standingsOpponent and membersByOpponent[standingsOpponent] then
		return membersByOpponent[standingsOpponent]
	end

	local member = Array.find(state, function(stateMember)
		return Opponent.same(matchOpponent, stateMember.opponent)
	end)
	if member then
		standingsOpponentByMatchOpponent[matchOpponent] = member.opponent
	end
	return member
end

return TiebreakerMembers
