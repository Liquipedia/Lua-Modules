---
-- @Liquipedia
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local p = {}

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchLegacyUtil = Lua.import('Module:MatchGroup/Legacy/Util')

local MAX_NUM_PLAYERS = 10

function p.storeMatch(match2)
	local match = p._convertParameters(match2)

	match.games = p.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function p.storeGames(match, match2)
	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game = Table.deepCopy(game)
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local opponents = Json.parseIfString(game.opponents) or {}
		local scores = Array.map(opponents, Operator.property('score'))
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

function p._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for i = 1, MAX_NUM_PLAYERS do
				local player = opponentmatch2players[i] or {}
				opponentplayers['p' .. i] = player.name or ''
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix .. 'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
		elseif opponent.type == 'solo' then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		elseif opponent.type == 'literal' then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
	if walkover then
		match.resulttype = walkover:lower()
		match.walkover = nil
	end

	return match
end

return p
