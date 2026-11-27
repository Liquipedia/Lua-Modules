---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 2000, notable = 2000},
	maxCoaches = 6,
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
			},
		},
		[2] = {
			points = {
				general = 10000,
				monthly = 50,
				weekly = 25,
			},
		},
		[3] = {
			points = {
				general = 1000,
				monthly = 50,
				weekly = 25,
			},
		},
		[4] = {
			points = {
				general = 300,
				monthly = 50,
				weekly = 25,
			},
		},
		[5] = {
			points = {
				general = 100,
				monthly = 50,
				weekly = 25,
			},
		},
	},
}
