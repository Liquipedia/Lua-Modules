---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Utils')

local Config = {}

local REGION_TO_SUPERREGION = {
	['World'] = 'Global',
	['Europe'] = 'EMEA',
	['Turkey'] = 'EMEA',
	['Middle East'] = 'EMEA',
	['Arab States'] = 'EMEA',
	['CIS'] = 'EMEA',
	['China'] = 'CN',
	['Americas'] = 'Americas',
	['North America'] = 'Americas',
	['Latin America North'] = 'Americas',
	['Latin America South'] = 'Americas',
	['Brazil'] = 'Americas',
	['Taiwan'] = 'APAC',
	['Hong Kong'] = 'APAC',
	['Macau'] = 'APAC',
	['Korea'] = 'APAC',
	['Japan'] = 'APAC',
	['Oceania'] = 'APAC',
	['Asia-Pacific'] = 'APAC',
	['Southeast Asia'] = 'APAC',
	['Vietnam'] = 'APAC',
	['Thailand'] = 'APAC',
	['Singapore'] = 'APAC',
	['Indonesia'] = 'APAC',
	['Philippines'] = 'APAC',
	['Other'] = 'Other',
}

local REGIONS_IN_SUPERREGION = Table.mapValues(Table.groupBy(REGION_TO_SUPERREGION, function(region, superRegion)
	return superRegion
end), function(superRegion)
	return Array.extractKeys(superRegion)
end)

---@type FilterButtonCategory[]
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
		items = { 'Global', 'Americas', 'CN', 'EMEA', 'APAC', 'Other', },
		defaultItem = 'Other',
		itemToPropertyValues = function(region)
			-- Input is a region
			if REGION_TO_SUPERREGION[region] then
				return table.concat(REGIONS_IN_SUPERREGION[REGION_TO_SUPERREGION[region]], ',')
			end
			-- Input is a superRegion
			if REGIONS_IN_SUPERREGION[region] then
				return table.concat(REGIONS_IN_SUPERREGION[region], ',')
			end
			-- Unknown input
			return ''
		end,
		itemIsValid = function(region)
			return REGION_TO_SUPERREGION[region] ~= nil
		end,
		transform = function(region)
			return REGION_TO_SUPERREGION[region] or region
		end,
	},
}

return Config
