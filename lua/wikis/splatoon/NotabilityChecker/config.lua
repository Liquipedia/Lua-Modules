---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type NotabilityCheckerConfig
return {
	thresholds = {discussion = 750, notable = 800},
	maxParticipants = 10,
	maxCoaches = 5,
	placementDropOff = {
		default = 1,
	},
	tiers = {
		[1] = {
			ignoreDateLoss = true,
			points = {
				general = 10000,
				national = 10000,
			},
		},
		[2] = {
			ignoreDateLoss = true,
			points = {
				general = 800,
				national = 800,
			},
		},
		[3] = {
			ignoreDateLoss = true,
			points = {
				general = 300,
				national = 300,
			},
		},
		[4] = {
			ignoreDateLoss = true,
			points = {
				general = 150,
				national = 150,
			},
		},
	},
}
