---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 1600, notable = 1600},
	maxCoaches = 1,
	modeMultipliers = {
		team = 0.5,
	},
	placementDropOff = {
		default = 1,
		qualifier = 2,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 5000,
				qualifier = 1000,
				monthly = 2000,
				weekly = 2000,
				ffa = 1500,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = 2000,
				qualifier = 400,
				monthly = 1500,
				weekly = 1500,
				ffa = 1000,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = 1000,
				qualifier = 200,
				monthly = 800,
				weekly = 800,
				ffa = 500,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = 500,
				qualifier = 100,
				monthly = 400,
				weekly = 400,
				ffa = 200,
			},
		},
	},
}
