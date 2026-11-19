---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_2_POINTS = {
	{maxPlacement = 3, points = 10},
	{maxPlacement = 8, points = 5},
	{maxPlacement = 16, points = 2},
}

local TIER_3_POINTS = {
	{maxPlacement = 4, points = 5},
	{maxPlacement = 8, points = 2},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 400, notable = 500},
	maxCoaches = 0,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 10,
				monthly = 10,
				weekly = 10,
			},
		},
		[2] = {
			points = {
				general = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				weekly = TIER_2_POINTS,
			},
		},
		[3] = {
			points = {
				general = TIER_3_POINTS,
				monthly = TIER_3_POINTS,
				weekly = TIER_3_POINTS,
			},
		},
		[4] = {
			points = {
				general = {
					{maxPlacement = 2, points = 2},
				},
			},
		},
	},
}
