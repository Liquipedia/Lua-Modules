---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WIN_ONLY = {
	{maxPlacement = 1, points = 1},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 10, notable = 10},
	maxCoaches = 2,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 10,
				monthly = WIN_ONLY,
				weekly = WIN_ONLY,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 10},
					{maxPlacement = 8, points = 5},
				},
				monthly = WIN_ONLY,
				weekly = WIN_ONLY,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 4, points = 5},
					{maxPlacement = 8, points = 2},
				},
				monthly = WIN_ONLY,
				weekly = WIN_ONLY,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 2, points = 2},
				},
				monthly = WIN_ONLY,
				weekly = WIN_ONLY,
			},
		},
		[5] = {
			ignoreDateLoss = true,
			points = {
				monthly = WIN_ONLY,
				weekly = WIN_ONLY,
			},
		},
	},
}
