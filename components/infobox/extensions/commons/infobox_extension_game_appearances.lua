---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/GameApperances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Game = require('Module:Game')

local DEFAULT_MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT = 10

local Appearances = {}

----Provide a list of games compete by a player
---@param args {player: string?, numberOfPlayersInPlacement}?
---@return string[]?
function Appearances.player(args)
	if not args or not args.player then return end
	local numberOfPlayersInPlacement = args.numberOfPlayersInPlacement or DEFAULT_MAX_NUMBER_OF_PLAYERS_IN_PLACEMENT

	local conditions = Array.map(Array.range(1, numberOfPlayersInPlacement), function(index)
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
	return games
end

return Appearances
