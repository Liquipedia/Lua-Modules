---
-- @Liquipedia
-- page=Module:BroadCasterWeight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_TO_FACTOR = {
	8,
	4,
	2,
}

local BroadCasterWeight = {}

---@param tier string|integer?
---@param prizepool number?
---@param tierType string?
---@return number
function BroadCasterWeight.run(tier, prizepool, tierType)
	local tierFactor = TIER_TO_FACTOR[tonumber(tier)] or 1
	local tierTypeFactor = tierType == 'Qualifier' and 0.001 or 1
	local prizeFactor = tonumber(tier) == 1 and tonumber(prizepool) or 1

	return tierFactor * tierTypeFactor * prizeFactor
end

return BroadCasterWeight
