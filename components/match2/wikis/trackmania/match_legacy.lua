---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game = Table.deepCopy(game)
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = Json.parseIfString(game.scores or {})
		game.opponent1score = scores[1] or 0
		game.opponent2score = scores[2] or 0
		local res = mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. gameIndex,
			game
		)
		games = games .. res
	end
	return games
end

function MatchLegacy._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id

	if match2.walkover then
		match.resulttype = match2.walkover
		if match2.walkover == 'ff' or match2.walkover == 'dq' then
			match.walkover = match.winner
		else
			match.walkover = nil
		end
	end

	-- Handle Opponents
	local handleOpponent = function(index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentMatch2Players = opponent.match2players or {}
		if opponent.type == Opponent.team then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentPlayers = {}
			for playerIndex, player in ipairs(opponentMatch2Players) do
				opponentPlayers['p' .. playerIndex] = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name or '')
				opponentPlayers['p' .. playerIndex .. 'flag'] = player.flag or ''
				opponentPlayers['p' .. playerIndex .. 'dn'] = player.displayname or ''
			end
			match[prefix .. 'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentPlayers)
		elseif opponent.type == Opponent.solo then
			local player = opponentMatch2Players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return match
end

return MatchLegacy
