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

----Provide a list of games compete by a player
---@param args GameAppearancesArgs
---@return table?
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

	local games = {}
	Array.forEach(data, function(item)
		local game = Game.name{game = item.game}
		if game then
			table.insert(games, '[[' .. game .. ']]')
		end
	end)

	return Appearances.removeDuplicates(games)
end

function Appearances.removeDuplicates(games)
    HashSet = {}
	Array.forEach(games, function(game)
		HashSet[game] = true
	end)

	games = Array.extractKeys(HashSet)
	table.sort(games)

	return games
end

return Appearances
