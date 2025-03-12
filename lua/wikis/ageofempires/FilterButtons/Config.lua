local Config = {}
local Tier = require('Module:Tier/Utils')
local Game = require('Module:Game')

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
			return Tier.toName(tonumber(tier))
		end,
		expandKey = "game"
	},
	{
		name = 'game',
		property = 'game',
		expandable = true,
		load = function(category)
			category.items = Game.listGames({ordered = true})
		end,
		transform = function(game)
			return Game.icon({game = game, noSpan = true, noLink = true, size = '20x20px'})
		end
	}
}

return Config
