---
-- @Liquipedia
-- page=Module:Standings/DisplayUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local StandingsDisplayUtil = {}

---Returns the stats that get a column, skipping untitled and duplicate ones.
---Stats with the same title share a column (e.g. all match based stats show the match record),
---the column shows the first of them.
---@param standings StandingsModel
---@return {id: string, title: string?}[]
function StandingsDisplayUtil.statsToShow(standings)
	local seenTitlesBefore = {}
	return Array.filter(standings.additionalStats, function(tiebreaker)
		if not tiebreaker.title then
			return false
		end
		if seenTitlesBefore[tiebreaker.title] then
			return false
		end
		seenTitlesBefore[tiebreaker.title] = true
		return true
	end)
end

return StandingsDisplayUtil
