---
-- @Liquipedia
-- page=Module:Weight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weight = {}

function Weight.calc(prize, tier, place, tierType, offline)
	return Weight.weight(prize, tier, place, tierType, offline == 'Offline')
end

function Weight.weight(prizeMoney, tier, placement, tierType, isOffline)
	local tiermultiplier, baseweigth
	local placement2 = mw.text.split(placement or '', '-')
	if #placement2 > 1 then
		placement = (placement2[1] + placement2[2]) / 2
	end
	placement = (tonumber(placement) or 999)

	if tonumber(tier) == 1 then
		tiermultiplier = 8
		baseweight = 2000 / placement
	elseif tonumber(tier) == 2 then
		tiermultiplier = 4
		baseweight = 200 / placement
	elseif tonumber(tier) == 3 then
		tiermultiplier = 2
		baseweight = 20 / placement
	elseif (tier == 'Qualifier') or (tier == 'Show Match') then
		tiermultiplier = 0.5
		baseweight = 0
	else
		tiermultiplier = 1
		baseweight = 10 / placement
	end
	return (isOffline and 1.5 or 1) * tiermultiplier * (prizeMoney + baseweight ) / placement
end

return Weight
