---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

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
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		local extradata = Json.parseIfString(game2.extradata) or {}

		game.mode = extradata.maptype

		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = game2.scores or {}
		if type(scores) == 'string' then
			scores = Json.parse(scores)
		end
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

	if match.walkover == 'ff' or match.walkover == 'dq' then
		match.resulttype = match.walkover
		match.walkover = match.winner
	elseif match.walkover == 'l' then
		match.resulttype = match.walkover
		match.walkover = nil
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	local extradata = Json.parseIfString(match2.extradata) or {}
	match.extradata = {}

	local mvp = Json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		local players = {}
		for _, player in ipairs(mvp.players) do
			table.insert(players, player.name .. '|' .. player.displayname)
		end
		match.extradata.mvp = table.concat(players, ',')
		match.extradata.mvp = match.extradata.mvp .. ';' .. mvp.points
	end

	for index, map in pairs(match2.match2games or {}) do
		match.extradata['vodgame' .. index] = map.vod
	end
	match.extradata.matchsection = extradata.matchsection
	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' then
		if bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
	end

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match.extradata['team' .. index .. 'icon'] = opponent.icon
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}

			local playerIndex = 1
			while not Table.isEmpty(opponentmatch2players[playerIndex] or {}) do
				local player = opponentmatch2players[playerIndex]
				opponentplayers['p' .. playerIndex] = player.name or ''
				opponentplayers['p' .. playerIndex .. 'flag'] = player.flag or ''
				opponentplayers['p' .. playerIndex .. 'dn'] = player.displayname or ''
				playerIndex = playerIndex + 1
			end
			match[prefix .. 'players'] = opponentplayers
		elseif opponent.type == 'solo' then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		elseif opponent.type == 'literal' then
			match[prefix] = opponent.name or 'TBD'
		end

		if opponent.type == 'literal' then
			match.extradata['opponent' .. index .. 'literal'] = 'true'
		else
			match.extradata['opponent' .. index .. 'literal'] = 'false'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

return MatchLegacy
