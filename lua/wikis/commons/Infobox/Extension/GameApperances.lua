---
-- @Liquipedia
-- page=Module:Infobox/Extension/GameApperances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Game = require('Module:Game')
local Table = require('Module:Table')

local DEFAULT_MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT = 10

local Appearances = {}

----Provide a list of games compete by a player
---@param args {player: string?, numberOfPlayersInPlacement: integer?}?
---@return string[]?
function Appearances.player(args)
	if not args or not args.player then return end
	local numberOfPlayersInPlacement = args.numberOfPlayersInPlacement or DEFAULT_MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT

	local player = args.player:gsub(' ', '_')
	local playerWithoutUnderscores = args.player:gsub('_', ' ')

	local conditions = {
		'[[opponentname::' .. player .. ']]',
		'[[opponentname::' .. playerWithoutUnderscores .. ']]',
	}

	Array.forEach(Array.range(1, numberOfPlayersInPlacement), function(index)
		Array.appendWith(conditions,
			'[[opponentplayers_p' .. index .. '::' .. player .. ']]',
			'[[opponentplayers_p' .. index .. '::' .. playerWithoutUnderscores .. ']]'
		)
	end)

	local queriedGames = Table.map(mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = table.concat(conditions, ' OR '),
		query = 'game',
		groupby = 'game asc',
		limit = 1000,
	}), function(_, item) return Game.toIdentifier{game = item.game, useDefault = false}, true end)

	local orderedGames = Array.filter(Game.listGames{ordered = true}, function(game)
		return queriedGames[game]
	end)

	return Array.map(orderedGames, function(game)
		return Game.name{game = game}
	end)
end

return Appearances
