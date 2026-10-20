---
-- @Liquipedia
-- page=Module:Features/DurationStats/Lib/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DEFAULT_STAGE = 'Results'

local Util = {}

---@param match MatchGroupUtilMatch?
---@return string
function Util.getStageName(match)
	if not match then return DEFAULT_STAGE end
	return (match.section ~= DEFAULT_STAGE and match.section)
		or match.extradata.matchsection or DEFAULT_STAGE
end

---Returns the winner and the loser of a game, given the opponent index of the winner.
---@param match MatchGroupUtilMatch?
---@param gameWinner string|number|nil
---@return standardOpponent?
---@return standardOpponent?
function Util.getWinnerAndLoser(match, gameWinner)
	if not match then return end

	local winnerIndex = tonumber(gameWinner) or 0
	return match.opponents[winnerIndex], match.opponents[3 - winnerIndex]
end

return Util
