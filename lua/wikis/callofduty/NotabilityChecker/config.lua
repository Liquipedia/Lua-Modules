---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 12, notable = 15},
	maxParticipants = 8,
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 16, points = 15},
					{points = 10},
				},
				qualifier = {
					{maxPlacement = 1, points = 5},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 12},
					{maxPlacement = 3, points = 10},
					{maxPlacement = 8, points = 8},
					{maxPlacement = 12, points = 5},
					{maxPlacement = 16, points = 3},
					{points = 1},
				},
				qualifier = {
					{maxPlacement = 1, points = 3},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 3, points = 3},
					{maxPlacement = 8, points = 2},
					{maxPlacement = 12, points = 1},
				},
				qualifier = {
					{maxPlacement = 1, points = 1},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 3},
					{maxPlacement = 3, points = 1},
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
