---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/HeadToHead
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local HeadToHead = {}

---Resolves a tie with a head-to-head tiebreaker, by comparing every pair of tied opponents on the matches
---they played against each other only.
---An opponent is on top if it is at least as good as the other opponent in every pairing, and at the bottom
---if it is at most as good in every pairing. An opponent that is equal to all others is neither.
---This is done in a single pass, so the tops, the middle and the bottoms each stay one tied group.
---Splitting those further is up to the next tiebreakers (e.g. the same head-to-head tiebreaker listed again).
---@param tiedOpponents TiebreakerOpponent[]
---@param tiebreaker StandingsTiebreaker
---@return TiebreakerOpponent[][] # Groups ordered from best to worst, containing the original opponents
function HeadToHead.resolve(tiedOpponents, tiebreaker)
	local isTop = Array.map(tiedOpponents, function() return true end)
	local isBottom = Array.map(tiedOpponents, function() return true end)

	Array.forEach(tiedOpponents, function(_, indexA)
		Array.forEach(Array.range(indexA + 1, #tiedOpponents), function(indexB)
			local scopedOpponents = TiebreakerScope.restrictTo{tiedOpponents[indexA], tiedOpponents[indexB]}
			local valueA = tiebreaker:valueOf(scopedOpponents, scopedOpponents[1])
			local valueB = tiebreaker:valueOf(scopedOpponents, scopedOpponents[2])

			isTop[indexA] = isTop[indexA] and valueA >= valueB
			isBottom[indexA] = isBottom[indexA] and valueA <= valueB
			isTop[indexB] = isTop[indexB] and valueB >= valueA
			isBottom[indexB] = isBottom[indexB] and valueB <= valueA
		end)
	end)

	---@type TiebreakerOpponent[]
	local tops = {}
	---@type TiebreakerOpponent[]
	local middle = {}
	---@type TiebreakerOpponent[]
	local bottoms = {}
	Array.forEach(tiedOpponents, function(opponent, index)
		if isTop[index] == isBottom[index] then
			table.insert(middle, opponent)
		elseif isTop[index] then
			table.insert(tops, opponent)
		else
			table.insert(bottoms, opponent)
		end
	end)

	if #tops == 0 and #bottoms == 0 then
		return {tiedOpponents}
	end

	return Array.filter({tops, middle, bottoms}, function(group) return #group > 0 end)
end

return HeadToHead
