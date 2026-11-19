---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_1_POINTS = {
	{maxPlacement = 8, points = 12.5},
	{maxPlacement = 16, points = 10},
	{maxPlacement = 32, points = 7.5},
	{maxPlacement = 64, points = 5},
}

local TIER_2_POINTS = {
	{maxPlacement = 8, points = 8},
	{maxPlacement = 16, points = 6},
	{maxPlacement = 32, points = 5},
	{maxPlacement = 40, points = 4},
	{maxPlacement = 64, points = 2},
}

local TIER_3_POINTS = {
	{maxPlacement = 8, points = 3},
	{maxPlacement = 16, points = 2},
	{maxPlacement = 32, points = 1},
	{maxPlacement = 64, points = 0.5},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 9, notable = 10},
	maxParticipants = 10,
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 25},
					{maxPlacement = 16, points = 20},
					{maxPlacement = 32, points = 15},
					{maxPlacement = 64, points = 10},
				},
				qualifier = TIER_1_POINTS,
				misc = TIER_1_POINTS,
				monthly = TIER_1_POINTS,
				weekly = TIER_1_POINTS,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 16},
					{maxPlacement = 16, points = 12},
					{maxPlacement = 32, points = 10},
					{maxPlacement = 40, points = 8},
					{maxPlacement = 64, points = 4},
				},
				qualifier = TIER_2_POINTS,
				misc = TIER_2_POINTS,
				monthly = TIER_2_POINTS,
				weekly = TIER_2_POINTS,
				showmatch = TIER_2_POINTS,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 6},
					{maxPlacement = 16, points = 4},
					{maxPlacement = 32, points = 2},
					{maxPlacement = 64, points = 1},
				},
				qualifier = TIER_3_POINTS,
				misc = TIER_3_POINTS,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 4},
					{maxPlacement = 16, points = 2},
					{maxPlacement = 32, points = 1},
				},
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 2},
					{maxPlacement = 16, points = 1},
				},
			},
		},
	},
}
