---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
					{maxPlacement = 64, points = 10},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 10},
					{maxPlacement = 8, points = 5},
					{maxPlacement = 16, points = 2},
					{maxPlacement = 32, points = 1},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 2},
					{maxPlacement = 16, points = 1},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 2, points = 2},
					{maxPlacement = 4, points = 1},
				},
			},
		},
	},
}
