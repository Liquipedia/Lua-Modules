---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_2_POINTS = {
	{maxPlacement = 3, points = 15},
	{maxPlacement = 10, points = 10},
	{maxPlacement = 20, points = 5},
	{maxPlacement = 30, points = 2},
	{points = 1},
}

local TIER_3_POINTS = {
	{maxPlacement = 3, points = 8},
	{maxPlacement = 5, points = 5},
	{maxPlacement = 10, points = 3},
	{maxPlacement = 20, points = 2},
	{maxPlacement = 30, points = 1},
}

local TIER_4_POINTS = {
	{maxPlacement = 3, points = 5},
	{maxPlacement = 5, points = 3},
	{maxPlacement = 10, points = 2},
	{maxPlacement = 20, points = 1},
}

local TIER_5_POINTS = {
	{maxPlacement = 3, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 20, notable = 25},
	maxParticipants = 7,
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 25,
				monthly = 25,
				weekly = 25,
				qualifier = 25,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				weekly = TIER_2_POINTS,
				qualifier = TIER_2_POINTS,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_3_POINTS,
				monthly = TIER_3_POINTS,
				weekly = TIER_3_POINTS,
				qualifier = TIER_3_POINTS,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_4_POINTS,
				monthly = TIER_4_POINTS,
				weekly = TIER_4_POINTS,
				qualifier = TIER_4_POINTS,
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_5_POINTS,
				monthly = TIER_5_POINTS,
				weekly = TIER_5_POINTS,
				qualifier = TIER_5_POINTS,
			},
		},
	},
}
