---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 300, notable = 300},
	maxCoaches = 5,
	modeMultipliers = {
		taiko = 1.2,
		catch = 1.2,
		['mania 7k'] = 1.2,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 300},
					{maxPlacement = 6, points = 250},
					{maxPlacement = 8, points = 200},
					{maxPlacement = 16, points = 100},
					{points = 50},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 150},
					{maxPlacement = 2, points = 100},
					{maxPlacement = 4, points = 80},
					{maxPlacement = 6, points = 60},
					{maxPlacement = 8, points = 40},
					{maxPlacement = 16, points = 20},
					{points = 10},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 30},
					{maxPlacement = 2, points = 20},
					{maxPlacement = 4, points = 15},
					{maxPlacement = 6, points = 10},
					{maxPlacement = 8, points = 7},
					{maxPlacement = 16, points = 3},
					{points = 2},
				},
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 5},
					{maxPlacement = 2, points = 4},
					{maxPlacement = 4, points = 3},
					{maxPlacement = 6, points = 2},
					{maxPlacement = 8, points = 1},
				},
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 2},
					{maxPlacement = 2, points = 1},
				},
			},
		},
	},
}
