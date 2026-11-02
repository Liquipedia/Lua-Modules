---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Members
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local TiebreakerMembers = {}

---A match as the standings import it, which also knows the standings opponent each of its opponents is.
---@class StandingsTiebreakerMatch: MatchGroupUtilMatch
---@field standingsOpponents standardOpponent[] # The standings opponent of each opponent of the match

---@type table<TiebreakerOpponent[], table<standardOpponent, TiebreakerOpponent>>
local membersByState = setmetatable({}, {__mode = 'k'})

---Index of the standings opponent in the match, 0 if it is not part of it.
---@param match StandingsTiebreakerMatch
---@param opponent standardOpponent
---@return integer
function TiebreakerMembers.opponentIndex(match, opponent)
	for index, standingsOpponent in ipairs(match.standingsOpponents) do
		if standingsOpponent == opponent then
			return index
		end
	end
	return 0
end

---Finds the member of the state (the opponents of a round) that a standings opponent is.
---@param state TiebreakerOpponent[]
---@param opponent standardOpponent
---@return TiebreakerOpponent?
function TiebreakerMembers.find(state, opponent)
	local membersByOpponent = membersByState[state]
	if not membersByOpponent then
		membersByOpponent = Table.map(state, function(_, member)
			return member.opponent, member
		end)
		membersByState[state] = membersByOpponent
	end
	return membersByOpponent[opponent]
end

return TiebreakerMembers
