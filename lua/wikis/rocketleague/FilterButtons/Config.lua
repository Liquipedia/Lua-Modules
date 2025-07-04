---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local Config = {}

local REGION_TO_SUPERREGION = {
	['Europe'] = 'EU',
	['North America'] = 'NA',
	['Oceania'] = 'OCE',
	['Latin America North'] = 'SAM',
	['Latin America South'] = 'SAM',
	['Brazil'] = 'SAM',
	['South America'] = 'SAM',
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
		defaultItems = {'1', '2', '3'},
		transform = function(tier)
			return Tier.toName(tier)
		end,
		expandKey = 'region',
	},
	{
		name = 'region',
		property = 'region',
		expandable = true,
		items = {'EU', 'NA', 'OCE', 'SAM', 'Other'},
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
