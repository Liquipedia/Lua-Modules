---
-- @Liquipedia
-- page=Module:FilterButtons/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Config = {}
local Tier = require('Module:Tier/Utils')
local Game = require('Module:Game')
local HtmlWidgets = require('Module:Widget/Html/All')

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
		transform = function(tier)
			return Tier.toName(tonumber(tier))
		end,
	},
	{
		name = 'game',
		property = 'game',
		load = function(category)
			category.items = Game.listGames{ordered = true}
		end,
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
