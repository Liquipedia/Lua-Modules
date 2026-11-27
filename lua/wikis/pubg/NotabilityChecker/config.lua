---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 15, notable = 15},
	maxCoaches = 6,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 3, points = 10},
					{maxPlacement = 8, points = 5},
					{maxPlacement = 12, points = 3},
					{points = 1},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 3, points = 7},
					{maxPlacement = 4, points = 3},
					{maxPlacement = 8, points = 2},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 3, points = 3},
					{maxPlacement = 4, points = 2},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 2, points = 1},
				},
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
	},
}
