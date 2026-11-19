---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_1_POINTS = {
	{maxPlacement = 16, points = 15},
	{points = 10},
}

local TIER_2_POINTS = {
	{maxPlacement = 1, points = 12},
	{maxPlacement = 3, points = 10},
	{maxPlacement = 8, points = 8},
	{maxPlacement = 12, points = 5},
	{maxPlacement = 16, points = 3},
	{points = 1},
}

local TIER_3_POINTS = {
	{maxPlacement = 1, points = 5},
	{maxPlacement = 3, points = 3},
	{maxPlacement = 8, points = 2},
	{maxPlacement = 12, points = 1},
}

local TIER_4_POINTS = {
	{maxPlacement = 1, points = 3},
	{maxPlacement = 3, points = 1},
}

local TIER_5_POINTS = {
	{maxPlacement = 1, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 12, notable = 15},
	maxParticipants = 10,
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_1_POINTS,
				individual = TIER_1_POINTS,
				qualifier = {
					{maxPlacement = 16, points = 5},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_2_POINTS,
				individual = TIER_2_POINTS,
				qualifier = {
					{maxPlacement = 3, points = 3},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_3_POINTS,
				individual = TIER_3_POINTS,
				qualifier = {
					{maxPlacement = 3, points = 1},
				},
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
