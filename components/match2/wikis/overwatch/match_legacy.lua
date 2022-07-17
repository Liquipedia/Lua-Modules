---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})

function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy._convertParameters(match2)

	if options.storeSmw then
		MatchLegacy.storeMatchSMW(match, match2)
	end

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			"legacymatch_" .. match2.match2id,
			match
		)
	end
end

function MatchLegacy.storeMatchSMW(match, match2)
	local streams = json.parseIfString(match.stream or {})
	local icon = Variables.varDefault('tournament_icon')
	mw.smw.subobject({
		'legacymatch_' .. match2.match2id,
		'is map number=1',
		'has team left=' .. (match.opponent1 or ''),
		'has team right=' .. (match.opponent2 or ''),
		'Has map date=' .. (match.date or ''),
		'Has tournament=' .. mw.title.getCurrentTitle().prefixedText,
		'Has tournament tier=' .. (match.liquipediatier or ''),
		'Has match stream=' .. (streams.stream or ''),
		'Has match twitch=' .. (streams.twitch or ''),
		'Has match twitch2=' .. (streams.twitch2 or ''),
		'Has match youtube=' .. (streams.youtube or ''),
		'Has match vod=' .. (match.vod or ''),
		'Has tournament name=' .. Logic.emptyOr(match.tickername, match.name, ''),
		'Has tournament icon=' .. (icon or ''),
		'Has winner=' .. (match.winner or ''),
		'Has team left score=' .. (match.opponent1score or '0'),
		'Has team right score=' .. (match.opponent2score or '0'),
		'Has exact time=' .. (Logic.readBool(match.dateexact) and 'true' or 'false'),
		'Is finished=' .. (Logic.readBool(match.finished) and 'true' or 'false'),
	 })
end

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		-- Extradata
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		game.extradata = mw.ext.LiquipediaDB.lpdb_create_json(game.extradata)
		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = game2.scores or {}
		if type(scores) == 'string' then
			scores = json.parse(scores)
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
		match.walkover = match.winner
	elseif match.walkover == 'l' then
		match.walkover = nil
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = json.parseIfString(match2.extradata)

	local mvp = json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		match.extradata.mvp = table.concat(mvp.players, ',')
		match.extradata.mvp = match.extradata.mvp .. ';' .. mvp.points
	end

	match.extradata.matchsection = extradata.matchsection
	match.extradata.bestofx = tostring(match2.bestof)
	local bracketData = json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' then
		if bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
	end

	match.extradata = mw.ext.LiquipediaDB.lpdb_create_json(match.extradata)

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent'..index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for i = 1,10 do
				local player = opponentmatch2players[i] or {}
				opponentplayers['p' .. i] = player.name or ''
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
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

	return match
end

return MatchLegacy
