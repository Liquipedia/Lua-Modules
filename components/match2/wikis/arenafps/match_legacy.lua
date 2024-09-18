---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Array = require('Module:Array')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

---@param match2 table
function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

---@param match table
---@param match2 table
---@return string
function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game = Table.deepCopy(game)
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = Json.parseIfString(game.scores) or {}
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

---@param match2 table
---@return table
function MatchLegacy._convertParameters(match2)
	---@type table
	local match = Table.filterByKey(match2, function(key) return not String.startsWith(key, 'match2') end)

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
			Array.forEach(opponentmatch2players, function(player)
				opponentplayers['p' .. index] = player.name or ''
				opponentplayers['p' .. index .. 'flag'] = player.flag or ''
				opponentplayers['p' .. index .. 'dn'] = player.displayname or ''
			end)
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

	if match2.walkover then
		match.resulttype = match2.walkover
		match.walkover = nil
	end

	return match
end

return MatchLegacy
