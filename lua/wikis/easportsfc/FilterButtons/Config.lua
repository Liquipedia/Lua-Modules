---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Game = Lua.import('Module:Game')
local Tier = Lua.import('Module:Tier/Utils')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

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
		items = {'fc 26', 'fc mobile', 'fc online'},
		expandable = true,
		transform = function(game)
			return HtmlWidgets.Fragment{
				children = {
					Game.icon{game = game, noSpan = true, noLink = true, size = '20x20px'},
					HtmlWidgets.Span{
						classes = {'mobile-hide'},
						children = {
							'&nbsp;',
							Game.text{game = game, noLink = true, useAbbreviation = true},
						}
					}
				}
			}
		end
	}
}

return Config
