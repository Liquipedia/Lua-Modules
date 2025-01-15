---
-- @Liquipedia
-- wiki=valorant
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
		defaultItems = { '1', '2', '3' },
		transform = function(tier)
			return Tier.toName(tier)
		end,
		expandKey = 'region',
	},
	{
		name = 'region',
		property = 'region',
		expandable = true,
		items = {
			'Europe', 'North America', 'Korea', 'China', 'Japan', 'Latin America North',
			'Latin America South', 'Taiwan', 'Oceania', 'Brazil', 'Other',
		},
		defaultItems = { 'Europe', 'North America', 'Korea', 'China', 'Brazil', 'Other' },
		transform = function(region)
			local regionToShortName = {
				['Europe'] = 'eu',
				['North America'] = 'na',
				['Korea'] = 'kr',
				['China'] = 'ch',
				['Japan'] = 'jp',
				['Latin America North'] = 'latam n',
				['Latin America South'] = 'latam s',
				['Taiwan'] = 'tw',
				['Oceania'] = 'oce',
				['Brazil'] = 'br',
				['Other'] = 'other',
			}
			return regionToShortName[region]
		end,
	},
}

return Config
