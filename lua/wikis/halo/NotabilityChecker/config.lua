---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 600, notable = 800},
	maxCoaches = 5,
	placementDropOff = {
		default = 1,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 20000,
				monthly = 50,
				weekly = 25,
				ffa = 10,
				daily = 5,
			},
		},
		[2] = {
			points = {
				general = 2000,
				monthly = 50,
				weekly = 25,
				ffa = 10,
				daily = 5,
			},
		},
		[3] = {
			points = {
				general = 600,
				monthly = 50,
				weekly = 25,
				ffa = 10,
				daily = 5,
			},
		},
		[4] = {
			points = {
				general = 350,
				monthly = 50,
				weekly = 25,
				ffa = 10,
				daily = 5,
			},
		},
	},
}
