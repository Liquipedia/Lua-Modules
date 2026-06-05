---
-- @Liquipedia
-- page=Module:PrizePool/Weight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local TIER_TO_FACTOR = {
	8,
	4,
	2,
}
local TIER_TO_BASE_WEIGHT = {
	2000,
	200,
	20
}

local Weight = {}

---@param prize number?
---@param tier string|integer
---@param place string
---@param tiertype string
---@param tournamentType string?
---@return number
function Weight.calc(prize, tier, place, tiertype, tournamentType)
	local isOffline = tournamentType == 'Offline'

	local placementFactor
	local placements = Array.parseCommaSeparatedString(place, '-')
	if placements[2] then
		placementFactor = (placements[1] + placements[2]) / 2
	else
		placementFactor = tonumber(placements[1]) or 999
	end

	local tierFactor = (tiertype == 'Qualifier' or tiertype == 'Showmatch') and 0.5
		or TIER_TO_FACTOR[tonumber(tier)]
		or 1

	local baseWeight = (tiertype == 'Qualifier' or tiertype == 'Showmatch') and 0
		or TIER_TO_BASE_WEIGHT[tonumber(tier)]
		or 10

	return (isOffline and 1.5 or 1) * tierFactor * (prize + baseWeight / placementFactor) / placementFactor
end

return Weight
