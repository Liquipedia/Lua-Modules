---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WARFARE_TIERS = {
	[1] = {
		ignoreDateLoss = true,
		points = {
			general = {
				{maxPlacement = 2, points = 20},
				{maxPlacement = 8, points = 10},
				{points = 5},
			},
		},
	},
	[2] = {
		ignoreDateLoss = true,
		points = {
			general = {
				{maxPlacement = 2, points = 5},
				{maxPlacement = 8, points = 3},
			},
		},
	},
	[3] = {
		ignoreDateLoss = true,
		points = {
			general = {
				{maxPlacement = 2, points = 1},
			},
		},
	},
}

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 30, notable = 30},
	maxCoaches = 3,
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 6, points = 20},
					{maxPlacement = 12, points = 15},
					{points = 10},
				},
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 6, points = 10},
					{maxPlacement = 12, points = 7},
					{points = 5},
				},
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = {
					{maxPlacement = 6, points = 5},
					{maxPlacement = 12, points = 2},
				},
			},
		},
	},
	modeTiers = {
		warfare = WARFARE_TIERS,
		wf = WARFARE_TIERS,
	},
}
