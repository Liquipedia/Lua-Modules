---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 400, notable = 600},
	maxCoaches = 5,
	placementDropOff = {
		default = 1,
	},
	tiers = {
		[1] = {
			points = {
				general = 600,
				monthly = 50,
				weekly = 25,
			},
		},
		[2] = {
			points = {
				general = 400,
				monthly = 50,
				weekly = 25,
			},
		},
		[3] = {
			points = {
				general = 300,
				monthly = 50,
				weekly = 25,
			},
		},
		[4] = {
			points = {
				general = 150,
				monthly = 50,
				weekly = 25,
			},
		},
		[5] = {
			points = {
				monthly = 50,
				weekly = 25,
			},
		},
	},
}
