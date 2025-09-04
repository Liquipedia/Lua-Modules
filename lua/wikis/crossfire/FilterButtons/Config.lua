---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Game = Lua.import('Module:Game')
local Tier = Lua.import('Module:Tier/Utils')

local Config = {}

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
		expandKey = "game",
	},
	{
		name = 'game',
		property = 'game',
		expandable = true,
		items = {'cf', 'cfm', 'cfhd'},
		transform = function(game)
			return Game.abbreviation{game = game, noSpan = true, noLink = true}
		end
	}
}

return Config
