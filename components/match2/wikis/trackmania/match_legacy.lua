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
local Team = require('Module:Team')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy._convertParameters(match2)

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id,
			match
		)
	end
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

	local opponent1 = match2.match2opponents[1] or {}
	local opponent1match2players = opponent1.match2players or {}
	if opponent1.type == Opponent.team then
		-- has to use template's pagename
		-- match.opponent1 = opponent1.name
		match.opponent1 = Team.queryRaw(opponent1.template).page
		match.opponent1score = (tonumber(opponent1.score) or 0) > 0
			and opponent1.score or 0
		local opponent1players = {}
		for i = 1, 10 do
			local player = opponent1match2players[i] or {}
			opponent1players['p' .. i] = player.name or ''
			opponent1players['p' .. i .. 'flag'] = player.flag or ''
		end
		match.opponent1players = Json.stringify(opponent1players)
	elseif opponent1.type == Opponent.solo then
		local player = opponent1match2players[1] or {}
		match.opponent1 = player.name
		match.opponent1score = (tonumber(opponent1.score) or 0) > 0
			and opponent1.score or 0
		match.opponent1flag = player.flag
	end

	local opponent2 = match2.match2opponents[2] or {}
	local opponent2match2players = opponent2.match2players or {}
	if opponent2.type == Opponent.team then
		-- has to use template's pagename
		-- match.opponent2 = opponent2.name
		match.opponent2 = Team.queryRaw(opponent2.template).page
		match.opponent2score = (tonumber(opponent2.score) or 0) > 0
			and opponent2.score or 0
		local opponent2players = {}
		for i = 1, 10 do
			local player = opponent2match2players[i] or {}
			opponent2players['p' .. i] = player.name or ''
			opponent2players['p' .. i .. 'flag'] = player.flag or ''
		end
		match.opponent2players = Json.stringify(opponent2players)
	elseif opponent2.type == Opponent.solo then
		local player = opponent2match2players[1] or {}
		match.opponent2 = player.name
		match.opponent2score = (tonumber(opponent2.score) or 0) > 0
			and opponent2.score or 0
		match.opponent2flag = player.flag
	end

	if match2.walkover then
		match.resulttype = match2.walkover
		if match2.walkover == 'ff' or match2.walkover == 'dq' then
			match.walkover = match.winner
		else
			match.walkover = nil
		end
	end

	return match
end

return MatchLegacy
