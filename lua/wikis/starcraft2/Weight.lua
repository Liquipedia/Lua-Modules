---
-- @Liquipedia
-- page=Module:Weight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local TIER_TO_FACTOR = {
	8,
	4,
	2,
}
local DEFAULT_PRIZE_VALUE = 0.0001

local Weight = {}

---@param prize number?
---@param tier string|integer
---@param place string
---@param tiertype string
---@return number
function Weight.calc(prize, tier, place, tiertype)
	place = string.lower(place or '')
	if Logic.isEmpty(place) or place == 'l' or place == 'dq' then
		return 0
	end

	local tierFactor = TIER_TO_FACTOR[tonumber(tier)] or 1

	local tierTypeFactor = tiertype == 'Qualifier' and 0.001 or 1

	prize = tonumber(prize)
	prize = prize ~= 0 and prize or DEFAULT_PRIZE_VALUE

	if place == 'w' or place == 'd' or place == 'q' then
		prize = 2
		place = '1'
	end

	local placementFactor = tonumber(Array.parseCommaSeparatedString(place, '-')[1]) --[[@as integer]]

	return tierFactor * (prize / placementFactor) * tierTypeFactor
end

return Weight
