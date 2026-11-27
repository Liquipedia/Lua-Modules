---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_1_POINTS = {
	{maxPlacement = 4, points = 1},
	{maxPlacement = 8, points = 0.8},
	{maxPlacement = 16, points = 0.6},
	{maxPlacement = 32, points = 0.4},
	{maxPlacement = 64, points = 0.2},
}

local TIER_2_POINTS = {
	{maxPlacement = 2, points = 1},
	{maxPlacement = 4, points = 0.8},
	{maxPlacement = 8, points = 0.6},
	{maxPlacement = 16, points = 0.3},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 20, notable = 25},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 25},
					{maxPlacement = 8, points = 20},
					{maxPlacement = 16, points = 15},
					{maxPlacement = 32, points = 10},
					{maxPlacement = 64, points = 5},
				},
				monthly = {
					{maxPlacement = 4, points = 15},
					{maxPlacement = 8, points = 12},
					{maxPlacement = 16, points = 9},
					{maxPlacement = 32, points = 6},
					{maxPlacement = 64, points = 3},
				},
				weekly = {
					{maxPlacement = 4, points = 10},
					{maxPlacement = 8, points = 8},
					{maxPlacement = 16, points = 6},
					{maxPlacement = 32, points = 4},
					{maxPlacement = 64, points = 2},
				},
				qualifier = TIER_1_POINTS,
				showmatch = TIER_1_POINTS,
			},
		},
		[2] = {
			points = {
				general = {
					{maxPlacement = 2, points = 15},
					{maxPlacement = 4, points = 12},
					{maxPlacement = 8, points = 9},
					{maxPlacement = 16, points = 4.5},
				},
				monthly = {
					{maxPlacement = 2, points = 10},
					{maxPlacement = 4, points = 8},
					{maxPlacement = 8, points = 6},
					{maxPlacement = 16, points = 3},
				},
				weekly = {
					{maxPlacement = 2, points = 5},
					{maxPlacement = 4, points = 4},
					{maxPlacement = 8, points = 3},
					{maxPlacement = 16, points = 1.5},
				},
				qualifier = TIER_2_POINTS,
				showmatch = TIER_2_POINTS,
			},
		},
		[3] = {
			points = {
				general = {
					{maxPlacement = 1, points = 10},
					{maxPlacement = 2, points = 8},
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 2},
				},
				monthly = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 2, points = 4},
					{maxPlacement = 4, points = 2.5},
					{maxPlacement = 8, points = 1},
				},
				weekly = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 2, points = 1.6},
					{maxPlacement = 4, points = 1},
					{maxPlacement = 8, points = 0.4},
				},
				qualifier = {
					{maxPlacement = 1, points = 1},
					{maxPlacement = 2, points = 0.8},
					{maxPlacement = 4, points = 0.5},
					{maxPlacement = 8, points = 0.2},
				},
			},
		},
		[4] = {
			points = {
				general = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 2, points = 2.5},
					{maxPlacement = 4, points = 1},
				},
				monthly = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 2, points = 1},
					{maxPlacement = 4, points = 0.4},
				},
				weekly = {
					{maxPlacement = 1, points = 1},
					{maxPlacement = 2, points = 0.5},
					{maxPlacement = 4, points = 0.2},
				},
			},
		},
		[5] = {
			points = {
				general = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 2, points = 1},
				},
				monthly = {
					{maxPlacement = 1, points = 1},
					{maxPlacement = 2, points = 0.5},
				},
			},
		},
	},
}
