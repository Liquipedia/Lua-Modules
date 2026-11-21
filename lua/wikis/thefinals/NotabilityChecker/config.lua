---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TIER_5_POINTS = {
	{maxPlacement = 1, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 8, notable = 10},
	maxCoaches = 1,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 10,
				misc = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 10},
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 2},
					{maxPlacement = 16, points = 1},
				},
				misc = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 4, points = 2},
					{maxPlacement = 8, points = 1},
				},
				misc = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 4, points = 1},
				},
				misc = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = TIER_5_POINTS,
				misc = TIER_5_POINTS,
			},
		},
	},
}
