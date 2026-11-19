---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 60, notable = 100},
	maxParticipants = 10,
	maxCoaches = 5,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 400},
				},
				monthly = {
					{maxPlacement = 4, points = 50},
				},
				weekly = {
					{maxPlacement = 4, points = 25},
				},
			},
		},
		[2] = {
			points = {
				general = {
					{maxPlacement = 4, points = 100},
					{maxPlacement = 16, points = 50},
				},
			},
		},
		[3] = {
			points = {
				general = {
					{maxPlacement = 3, points = 15},
					{maxPlacement = 4, points = 30},
					{maxPlacement = 16, points = 15},
				},
			},
		},
		[4] = {
			points = {
				general = {
					{maxPlacement = 3, points = 5},
					{maxPlacement = 4, points = 10},
					{maxPlacement = 16, points = 5},
				},
			},
		},
		[5] = {
			points = {
				general = {
					{maxPlacement = 3, points = 1},
					{maxPlacement = 4, points = 2},
					{maxPlacement = 16, points = 1},
				},
			},
		},
	},
}
