---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 700, notable = 700},
	maxCoaches = 5,
	-- https://liquipedia.net/rainbowsix/Liquipedia:Qualifier_Notability_Points
	placementDropOff = {
		default = 1,
		qualifier = 2,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 20000,
				qualifier = 200,
				monthly = 50,
				weekly = 25,
			},
		},
		[2] = {
			points = {
				general = 2000,
				qualifier = 100,
				monthly = 50,
				weekly = 25,
			},
		},
		[3] = {
			points = {
				general = 600,
				qualifier = 60,
				monthly = 50,
				weekly = 25,
			},
		},
		[4] = {
			points = {
				general = 350,
				qualifier = 35,
				monthly = 50,
				weekly = 25,
			},
		},
		[5] = {
			points = {
				general = 150,
				qualifier = 15,
				monthly = 50,
				weekly = 25,
			},
		},
	},
}
