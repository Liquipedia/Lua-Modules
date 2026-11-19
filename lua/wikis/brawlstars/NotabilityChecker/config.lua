---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_1_POINTS = {
	{maxPlacement = 4, points = 20},
	{maxPlacement = 8, points = 15},
	{maxPlacement = 16, points = 10},
}

local TIER_2_POINTS = {
	{maxPlacement = 1, points = 6},
	{maxPlacement = 2, points = 5},
	{maxPlacement = 4, points = 4},
	{maxPlacement = 16, points = 3},
}

local TIER_3_POINTS = {
	{maxPlacement = 1, points = 4},
	{maxPlacement = 2, points = 3},
	{maxPlacement = 4, points = 2},
	{maxPlacement = 16, points = 1},
}

local TIER_4_POINTS = {
	{maxPlacement = 1, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 12, notable = 15},
	maxParticipants = 5,
	maxCoaches = 3,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_1_POINTS,
				monthly = TIER_1_POINTS,
				weekly = TIER_1_POINTS,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				weekly = TIER_2_POINTS,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_3_POINTS,
				monthly = TIER_3_POINTS,
				weekly = TIER_3_POINTS,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_4_POINTS,
				monthly = TIER_4_POINTS,
				weekly = TIER_4_POINTS,
			},
		},
	},
}
