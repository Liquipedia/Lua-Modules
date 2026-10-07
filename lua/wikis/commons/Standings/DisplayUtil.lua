---
-- @Liquipedia
-- page=Module:Standings/DisplayUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local StandingsDisplayUtil = {}

---Returns the stats that get a column, skipping untitled and duplicate ones
---@param standings StandingsModel
---@return {id: string, title: string?}[]
function StandingsDisplayUtil.statsToShow(standings)
	local seenStatsBefore = {}
	return Array.filter(standings.additionalStats, function(tiebreaker)
		if not tiebreaker.title then
			return false
		end
		if seenStatsBefore[tiebreaker.id] then
			return false
		end
		seenStatsBefore[tiebreaker.id] = true
		return true
	end)
end

return StandingsDisplayUtil
