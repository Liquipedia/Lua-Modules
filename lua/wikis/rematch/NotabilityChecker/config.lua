---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_2_POINTS = {
	{maxPlacement = 1, points = 12.5},
	{maxPlacement = 4, points = 5},
	{points = 2.5},
}

local TIER_3_POINTS = {
	{maxPlacement = 1, points = 5},
	{maxPlacement = 4, points = 2.5},
	{points = 1.25},
}

local TIER_4_POINTS = {
	{maxPlacement = 1, points = 2.5},
	{maxPlacement = 4, points = 1.25},
	{points = 0.5},
}

local TIER_5_POINTS = {
	{maxPlacement = 1, points = 1.25},
	{maxPlacement = 4, points = 0.5},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 90, notable = 90},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 100,
				qualifier = 25,
				monthly = 25,
				weekly = 10,
				showmatch = 25,
			},
		},
		[2] = {
			points = {
				general = {
					{maxPlacement = 1, points = 50},
					{maxPlacement = 4, points = 20},
					{points = 10},
				},
				qualifier = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				weekly = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 4, points = 2},
					{points = 1},
				},
				showmatch = TIER_2_POINTS,
			},
		},
		[3] = {
			points = {
				general = {
					{maxPlacement = 1, points = 20},
					{maxPlacement = 4, points = 10},
					{points = 5},
				},
				qualifier = TIER_3_POINTS,
				monthly = TIER_3_POINTS,
				weekly = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 4, points = 1},
					{points = 0.5},
				},
				showmatch = TIER_3_POINTS,
			},
		},
		[4] = {
			points = {
				general = {
					{maxPlacement = 1, points = 10},
					{maxPlacement = 4, points = 5},
					{points = 2},
				},
				qualifier = TIER_4_POINTS,
				monthly = TIER_4_POINTS,
				weekly = {
					{maxPlacement = 1, points = 1},
					{maxPlacement = 4, points = 0.5},
					{points = 0.2},
				},
				showmatch = TIER_4_POINTS,
			},
		},
		[5] = {
			points = {
				general = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 4, points = 2},
				},
				qualifier = TIER_5_POINTS,
				monthly = TIER_5_POINTS,
				weekly = {
					{maxPlacement = 1, points = 0.5},
					{maxPlacement = 4, points = 0.2},
				},
				showmatch = TIER_5_POINTS,
			},
		},
	},
}
