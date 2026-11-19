---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 22, notable = 22},
	maxCoaches = 6,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 16, points = 20},
					{points = 15},
				},
				monthly = 0.5,
				weekly = 0.5,
				qualifier = {
					{maxPlacement = 1, points = 3},
				},
				showmatch = 0.5,
				misc = 0.5,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 12},
					{maxPlacement = 4, points = 10},
					{maxPlacement = 8, points = 7},
					{maxPlacement = 12, points = 4},
					{maxPlacement = 16, points = 2},
					{points = 1},
				},
				monthly = 0.5,
				weekly = 0.5,
				qualifier = {
					{maxPlacement = 1, points = 2},
				},
				showmatch = 0.5,
				misc = 0.5,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 6},
					{maxPlacement = 4, points = 3},
					{maxPlacement = 8, points = 2},
					{maxPlacement = 12, points = 1},
					{points = 0.5},
				},
				monthly = 0.5,
				weekly = 0.5,
				qualifier = {
					{maxPlacement = 1, points = 1},
				},
				showmatch = 0.5,
				misc = 0.5,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 3},
					{maxPlacement = 2, points = 1},
					{maxPlacement = 3, points = 3},
					{maxPlacement = 4, points = 1},
					{points = 0.5},
				},
				monthly = 0.5,
				weekly = 0.5,
				showmatch = 0.5,
				misc = 0.5,
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 1, points = 1},
					{points = 0.5},
				},
				monthly = 0.5,
				weekly = 0.5,
				showmatch = 0.5,
				misc = 0.5,
			},
		},
	},
}
