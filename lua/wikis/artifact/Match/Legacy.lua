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
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

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
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end
	match.links = nil

	local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
	if walkover then
		match.resulttype = match.walkover:lower()
		match.walkover = match.winner
	end

	match.staticid = match2.match2id

	match.extradata = {}

	local games = match2.match2games or {}
	for key, game in ipairs(games) do
		if String.isNotEmpty(game.vod) then
			match.extradata['vodgame' .. key] = game.vod
		end
	end

	-- Handle Opponents
	local handleOpponent = function (opponentIndex)
		local prefix = 'opponent'..opponentIndex
		local opponent = match2.match2opponents[opponentIndex] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match[prefix] = opponent.name
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for playerIndex = 1, 10 do
				local player = opponentmatch2players[playerIndex] or {}
				opponentplayers['p' .. playerIndex] = player.name or ''
				opponentplayers['p' .. playerIndex .. 'flag'] = player.flag or ''
				opponentplayers['p' .. playerIndex .. 'dn'] = player.displayname or ''
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
		local opponents = Json.parseIfString(game2.opponents) or {}

		-- Extradata
		local extradata = Json.parseIfString(game2.extradata) or {}
		game.extradata = Array.map(opponents, function(opponent, opponentIndex)
			local cnt = 0
			for _, player in ipairs(opponent.players) do
				if player.character then
					cnt = cnt + 1
					extradata['t' .. opponentIndex .. 'p' .. cnt] = player.character
				end
			end
		end)

		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = Array.map(opponents, Operator.property('score'))
		game.opponent1score = scores[1] or 0
		game.opponent2score = scores[2] or 0

		local res = mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. '_' .. gameIndex,
			Json.stringifySubTables(game)
		)
		games = games .. res
	end
	return games
end

return MatchLegacy
