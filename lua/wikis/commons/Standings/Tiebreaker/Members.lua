---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Members
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Table = Lua.import('Module:Table')

local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerMembers = {}

---Whether a match opponent is the given standings opponent. Cached, as every round compares the same opponents again
---and comparing different opponents can take team template lookups.
---@param matchOpponent standardOpponent
---@param opponent standardOpponent
---@return boolean
TiebreakerMembers.isSame = FnUtil.memoize2(function(matchOpponent, opponent)
	return Opponent.same(opponent, matchOpponent)
end)

---Index of the opponent in the match, 0 if it is not part of it.
---@param match MatchGroupUtilMatch
---@param opponent standardOpponent
---@return integer
function TiebreakerMembers.opponentIndex(match, opponent)
	for index, matchOpponent in ipairs(match.opponents) do
		if TiebreakerMembers.isSame(matchOpponent, opponent) then
			return index
		end
	end
	return 0
end

-- All rounds share the standings opponents, so the standings opponent of a match opponent is remembered
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
		membersByOpponent = Table.map(state, function(_, member)
			return member.opponent, member
		end)
		membersByState[state] = membersByOpponent
	end

	local standingsOpponent = standingsOpponentByMatchOpponent[matchOpponent]
	if standingsOpponent and membersByOpponent[standingsOpponent] then
		return membersByOpponent[standingsOpponent]
	end

	local member = Array.find(state, function(stateMember)
		return TiebreakerMembers.isSame(matchOpponent, stateMember.opponent)
	end)
	if member then
		standingsOpponentByMatchOpponent[matchOpponent] = member.opponent
	end
	return member
end

return TiebreakerMembers
