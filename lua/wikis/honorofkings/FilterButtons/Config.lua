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

local VERSION_TO_GAME = {
	['aovas'] = 'Honor of Kings',
	['hok'] = 'Honor of Kings',
	['hokic'] = 'Honor of Kings',
	['Honor of Kings'] = 'Honor of Kings',
	['Honor of Kings (KIC Version)'] = 'Honor of Kings',
	['Honor of Kings (Asian Games Version)'] = 'Honor of Kings',
	['aov'] = 'Arena of Valor',
	['Arena of Valor'] = 'Arena of Valor',
}

local VERSIONS_IN_GAME = Table.mapValues(Table.groupBy(VERSION_TO_GAME, function(version, baseGame)
	return baseGame
end), function(group)
	return Array.extractKeys(group)
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
		expandKey = 'game',
	},
	{
		name = 'game',
		property = 'game',
		expandable = true,
		items = { 'Honor of Kings', 'Arena of Valor'},
		defaultItem = {'Honor of Kings', 'Arena of Valor'},
		itemToPropertyValues = function(game)
			-- Input is a specific version
			if VERSION_TO_GAME[game] then
				return table.concat(VERSIONS_IN_GAME[VERSION_TO_GAME[game]], ',')
			end
			-- Input is already a base game
			if VERSIONS_IN_GAME[game] then
				return table.concat(VERSIONS_IN_GAME[game], ',')
			end
			-- Unknown input
			return ''
		end,
		itemIsValid = function(game)
			return VERSION_TO_GAME[game] ~= nil
		end,
		transform = function(game)
			local baseGame = VERSION_TO_GAME[game] or game
			local icon = require('Module:Game').icon({ game = baseGame, noSpan = true, noLink = true, size = '20x20px' })
			return icon .. '&nbsp;' .. baseGame
		end
	},
}

return Config
