local Config = {}
local Tier = require('Module:Tier/Utils')
local FnUtil = require('Module:FnUtil')
local Game = require('Module:Game')

Config.categories = {
	{
		name = 'liquipediatier',
		query = 'liquipediatier',
		load = function(category)
			category.items = {}
			for _, tier in Tier.iterate('tiers') do
				table.insert(category.items, tier.value)
			end
		end,
		defaultItems = {'1', '2', '3'},
		transform = function(tier)
			return Tier.toName(tier)
		end,
		expandKey = "liquipediatiertype",
		additionalClass = ''
	},
	{
		name = 'liquipediatiertype',
		query = 'liquipediatiertype',
		expandable = true,
		load = function(category)
			category.items = {}
			for _, tiertype in Tier.iterate('tierTypes') do
				table.insert(category.items, tiertype.value)
			end
			--table.insert(category.items, "")
		end,
		transform = function(tiertype)
			return tiertype
		end,
		additionalClass = ''
	},
}

return Config
