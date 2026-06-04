---
-- @Liquipedia
-- page=Module:Weight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weight = {}

function Weight.calc(prize, tier, place, tiertype)
	prize = tonumber(prize) or 0
	tier = tonumber(tier)
	place = string.lower(place or '')
	if
		place == 'l' or
		place == 'dq' or
		place == ''
	then
		return 0
	end

	if
		place == 'w' or
		place == 'd' or
		place == 'q'
	then
		prize = 2
		place = 1
	end

	local tierCovert = {
		8,
		4,
		2,
	}
	local typeCovert = {
		qualifier = 0.001,
		external = 0.1,
	}
	if prize == 0 then
		prize = 0.0001
	end

	local tierFactor = tierCovert[tier] or 1
	local placementFactor = mw.text.split(place, '-', true)[1]
	local tierTypeFactor = typeCovert[string.lower(tiertype or '')] or 1

	return tierFactor * (prize / placementFactor) * tierTypeFactor
end

return Weight
