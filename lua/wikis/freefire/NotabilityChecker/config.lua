---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_2_POINTS = {
	{maxPlacement = 3, points = 8},
	{maxPlacement = 8, points = 5},
	{maxPlacement = 12, points = 3},
}

local TIER_3_POINTS = {
	{maxPlacement = 2, points = 5},
	{maxPlacement = 3, points = 3},
	{maxPlacement = 8, points = 2},
}

local TIER_4_POINTS = {
	{maxPlacement = 1, points = 2},
	{maxPlacement = 2, points = 1},
}

local TIER_5_POINTS = {
	{maxPlacement = 1, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 10, notable = 8},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 10,
				individual = 10,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_2_POINTS,
				individual = TIER_2_POINTS,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_3_POINTS,
				individual = TIER_3_POINTS,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_4_POINTS,
				individual = TIER_4_POINTS,
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_5_POINTS,
				individual = TIER_5_POINTS,
			},
		},
	},
}
