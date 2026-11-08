---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TiebreakerMatchUtil = {}

---Match results including overtime. The `match` scoreboard only holds regulation results when overtime is tracked.
---@param opponent TiebreakerOpponent
---@return {w: integer, d: integer, l: integer}
function TiebreakerMatchUtil.getMatches(opponent)
	local overtime = opponent.overtime or {}
	return {
		w = opponent.match.w + (overtime.w or 0),
		d = opponent.match.d,
		l = opponent.match.l + (overtime.l or 0),
	}
end

return TiebreakerMatchUtil
