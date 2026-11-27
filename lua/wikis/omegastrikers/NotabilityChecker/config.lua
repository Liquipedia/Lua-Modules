---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 400, notable = 500},
	maxCoaches = 0,
	modeMultipliers = {
		['2v2'] = 0.5,
		['1v1'] = 0.25,
	},
	placementDropOff = {
		default = 1,
		qualifier = 2,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 1000,
				qualifier = 250,
				showmatch = 250,
				school = 500,
				monthly = 200,
				weekly = 50,
			},
		},
		[2] = {
			points = {
				general = 500,
				qualifier = 125,
				showmatch = 125,
				school = 250,
				monthly = 150,
				weekly = 40,
			},
		},
		[3] = {
			points = {
				general = 350,
				qualifier = 75,
				showmatch = 75,
				school = 150,
				monthly = 100,
				weekly = 30,
			},
		},
		[4] = {
			points = {
				general = 175,
				qualifier = 25,
				showmatch = 30,
				school = 100,
				monthly = 50,
				weekly = 20,
			},
		},
		[5] = {
			points = {
				general = 10,
				qualifier = 3,
				showmatch = 3,
				school = 5,
				monthly = 10,
				weekly = 10,
			},
		},
	},
}
