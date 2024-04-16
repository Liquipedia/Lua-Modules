---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/GameApperances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Game = require('Module:Game')

local MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT = 10

local Appearances = {}

---@class GameAppearancesArgs
---@field player string?

----Provide a list of games compete by a player
---@param args GameAppearancesArgs
---@return string[] | nil
function Appearances.player(args)
	if not args or not args.player then return end

	local conditions = Array.map(Array.range(1, MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT), function(index)
		return '[[opponentplayers_p' .. index .. '::' .. args.player .. ']]'
	end)
	table.insert(conditions, '[[opponentname::' .. args.player .. ']]')

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = table.concat(conditions, ' OR '),
		query = 'game',
		groupby = 'game asc',
		limit = 1000,
	})

	local games = Array.unique(Array.map(data, function(item)
		return Game.name{game = item.game}
	end))
	table.sort(games)
	return Array.map(games, function(game)
		return game
	end)
end

return Appearances
