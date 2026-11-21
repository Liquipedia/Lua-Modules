---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 30, notable = 30},
	maxCoaches = 5,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 8, points = 30},
					{maxPlacement = 16, points = 20},
					{points = 15},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 20},
					{maxPlacement = 8, points = 10},
					{maxPlacement = 16, points = 4},
					{points = 1},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 2, points = 10},
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 3},
					{maxPlacement = 16, points = 1},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 2, points = 3},
					{maxPlacement = 4, points = 1},
				},
			},
		},
	},
}
