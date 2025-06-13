---
-- @Liquipedia
-- page=Module:Match/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')

local MatchUtil = {}

---@param matchOpponent table
---@param gameOpponent table
function MatchUtil.enrichGameOpponentFromMatchOpponent(matchOpponent, gameOpponent)
	local newGameOpponent = Table.deepMerge(matchOpponent, gameOpponent)
	-- These values are only allowed to come from Game and not Match
	newGameOpponent.placement = gameOpponent.placement
	newGameOpponent.score = gameOpponent.score
	newGameOpponent.status = gameOpponent.status

	-- TODO: match2players vs players duplication. Which one to keep? How to merge?

	return newGameOpponent
end

return MatchUtil
