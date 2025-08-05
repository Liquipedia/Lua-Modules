---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Game = require('Module:Game')
local Tier = require('Module:Tier/Utils')

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
		load = function(category)
			category.items = Game.listGames({ordered = true})
		end,
		transform = function(game)
			return Game.icon({game = game, noSpan = true, noLink = true, size = '20x20px'}) ..
				'&nbsp;' .. Game.name({game = game})
		end
	}
}

return Config
