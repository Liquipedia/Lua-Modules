---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 14, notable = 15},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 32, points = 5},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 3},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 3},
					{maxPlacement = 8, points = 0.9},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 2, points = 1},
				},
			},
		},
	},
}
