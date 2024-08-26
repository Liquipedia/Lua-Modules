---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local _GAME_EXTRADATA_CONVERTER = {
	ban = 'b',
	champion = 'h',
}

function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end
	match.links = nil

	if Logic.isNotEmpty(match.walkover) then
		match.resulttype = match.walkover
		match.walkover = match.winner
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = Json.parseIfString(match2.extradata)
	match.extradata.gamecount = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	match.extradata.matchsection = extradata.matchsection
	match.extradata.mvpteam = extradata.mvpteam
	local mvp = Json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		local players = {}
		for _, player in ipairs(mvp.players) do
			table.insert(players, player.name .. '|' .. player.displayname)
		end
		match.extradata.mvp = table.concat(players, ',')
		match.extradata.mvp = match.extradata.mvp .. ';' .. mvp.points
	end
	match.extradata.comment = extradata.comment

	local opponents = match2.match2opponents or {}
	match.extradata.team1icon = (opponents[1] or {}).icon
	match.extradata.team2icon = (opponents[2] or {}).icon
	match.extradata.opponent1literal = tostring((opponents[1] or {}).type == 'literal')
	match.extradata.opponent2literal = tostring((opponents[2] or {}).type == 'literal')
	match.extradata.opponent1game = 'false'
	match.extradata.opponent2game = 'false'

	local games = match2.match2games or {}
	for key, game in ipairs(games) do
		if String.isNotEmpty(game.vod) then
			match.extradata['vodgame' .. key] = game.vod
		end
	end

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent'..index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match[prefix] = opponent.name
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for i = 1, 10 do
				local player = opponentmatch2players[i] or {}
				opponentplayers['p' .. i] = player.name or ''
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = opponentplayers
		elseif opponent.type == 'solo' then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix..'flag'] = player.flag
		elseif opponent.type == 'literal' then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)

		-- Extradata
		local extradata = Json.parseIfString(game2.extradata)
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		game.extradata.team1side = extradata.team1side
		game.extradata.team2side = extradata.team2side

		local parameterType, teamIndex, parameterIndex
		for key, item in pairs(extradata) do
			teamIndex, parameterType, parameterIndex = string.match(key, 'team(%d)(%a+)(%d)')
			parameterType = _GAME_EXTRADATA_CONVERTER[parameterType or '']
			if parameterType then
				game.extradata['t' .. teamIndex .. parameterType .. parameterIndex] = item
			end
		end

		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local winner = tonumber(game.winner) or 0
		game.opponent1score = winner == 1 and 1 or 0
		game.opponent2score = winner == 2 and 1 or 0
		local res = mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. '_' .. gameIndex,
			Json.stringifySubTables(game)
		)
		games = games .. res
	end
	return games
end

return MatchLegacy
