---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Tier = require('Module:Tier/Utils')
local Config = {}

Config.categories = {
	{
		name = 'liquipediatier',
		property = 'liquipediaTier',
		load = function(category)
			category.items = {}
			for _, tier in Tier.iterate('tiers') do
				table.insert(category.items, tier.value)
			end
		end,
		defaultItems = {},
		transform = function(tier)
			return Tier.toName(tier)
		end,
		hasFeatured = true,
		featuredByDefault = true,
		expandKey = "liquipediatiertype",
	},
	{
		name = 'liquipediatiertype',
		property = 'liquipediaTierType',
		expandable = true,
		load = function(category)
			category.items = {}
			for _, tiertype in Tier.iterate('tierTypes') do
				table.insert(category.items, Tier.toIdentifier(tiertype.value))
			end
		end,
		transform = function(tiertype)
			return select(2, Tier.toName(1, tiertype))
		end,
	},
}

return Config
