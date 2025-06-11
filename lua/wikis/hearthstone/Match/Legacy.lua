---
-- @Liquipedia
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Opponent = require('Module:Opponent')

local MatchLegacyUtil = Lua.import('Module:MatchGroup/Legacy/Util')

function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy._convertParameters(match2)
	---@type table
	local match = Table.filterByKey(Table.deepCopy(match2), function(key) return not String.startsWith(key, 'match2') end)
	match.links = nil

	local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
	if walkover then
		match.resulttype = walkover:lower()
		match.walkover = match.winner
	end

	match.staticid = match2.match2id


	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent'..index
		local opponent = match2.match2opponents[index] or {}
		match[prefix .. 'score'] = tonumber(opponent.score) or 0
		if opponent.type == Opponent.team then
			match[prefix] = opponent.name
			local players = {}
			Array.forEach(opponent.match2players or {}, function(player, playerIndex)
				players['p' .. playerIndex] = player.name or ''
				players['p' .. playerIndex .. 'flag'] = player.flag or ''
				players['p' .. playerIndex .. 'dn'] = player.displayname or ''
			end)
			match[prefix .. 'players'] = players
		elseif opponent.type == Opponent.solo then
			local player = (opponent.match2players or {})[1] or {}
			match[prefix] = player.name
			match[prefix..'flag'] = player.flag
		elseif opponent.type == Opponent.literal then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

function MatchLegacy.storeGames(match, match2)
	local games = Array.map(match2.match2games or {}, function(game2, gameIndex)
		local game = Table.deepCopy(game2)

		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local winner = tonumber(game.winner)
		game.opponent1score = winner == 1 and 1 or 0
		game.opponent2score = winner == 2 and 1 or 0
		return mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. '_' .. gameIndex,
			Json.stringifySubTables(game)
		)
	end)
	return table.concat(games)
end

return MatchLegacy
