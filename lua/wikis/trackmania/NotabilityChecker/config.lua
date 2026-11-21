---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_1_POINTS = {
	{maxPlacement = 16, points = 100},
	{points = 8},
}

local TIER_2_POINTS = {
	{maxPlacement = 8, points = 80},
	{maxPlacement = 16, points = 8},
	{points = 4},
}

local TIER_3_POINTS = {
	{maxPlacement = 3, points = 40},
	{maxPlacement = 8, points = 8},
	{points = 4},
}

local TIER_4_POINTS = {
	{maxPlacement = 3, points = 12},
	{maxPlacement = 7, points = 4},
	{maxPlacement = 16, points = 2},
	{points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 80, notable = 100},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_1_POINTS,
				monthly = TIER_1_POINTS,
				campaign = TIER_1_POINTS,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				campaign = TIER_2_POINTS,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_3_POINTS,
				monthly = TIER_3_POINTS,
				campaign = TIER_3_POINTS,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_4_POINTS,
				monthly = TIER_4_POINTS,
				campaign = TIER_4_POINTS,
			},
		},
	},
}
