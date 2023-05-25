---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})

local _NUMBER_OF_PLAYERS_TO_STORE = 10

function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy._convertParameters(match2)

	if options.storeSmw then
		MatchLegacy.storeMatchSMW(match, match2)
	end

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id,
			match
		)
	end
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

	if match.resulttype == 'draw' then
		match.resulttype = ''
		match.winner = 'draw'
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = Json.parseIfString(match2.extradata)
	match.extradata.gamecount = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	match.extradata.matchsection = extradata.matchsection
	local mvp = Json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		local players = {}
		for _, player in ipairs(mvp.players) do
			table.insert(players, player.name .. '|' .. player.displayname)
		end
		match.extradata.mvp = table.concat(players, ',')
		match.extradata.mvp = match.extradata.mvp .. ';' .. mvp.points
	end

	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' then
		if bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
	end

	local opponents = match2.match2opponents or {}
	match.extradata.team1icon = (opponents[1] or {}).icon
	match.extradata.team2icon = (opponents[2] or {}).icon

	local games = match2.match2games or {}
	for key, game in ipairs(games) do
		if String.isNotEmpty(game.vod) then
			match.extradata['vodgame' .. key] = game.vod
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
			for i = 1, _NUMBER_OF_PLAYERS_TO_STORE do
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

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)

		-- Extradata
		local extradata = Json.parseIfString(game2.extradata)
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		for key, item in pairs(extradata) do
			local teamIndex, typeIndicator, typeIndex = string.match(key, 'team(%d)(%a+)(%d)')
			if typeIndicator and typeIndex then
				local newKey = 't' .. teamIndex .. string.sub(typeIndicator, 1, 1) .. typeIndex
				game.extradata[newKey] = item
			end
		end
		game.extradata.team1side = extradata.team1side
		game.extradata.team2side = extradata.team2side

		game.extradata.parent = game2.parent

		game.extradata = mw.ext.LiquipediaDB.lpdb_create_json(game.extradata)

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
			'legacygame_' .. match2.match2id .. gameIndex,
			game
		)
		games = games .. res
	end
	return games
end

function MatchLegacy.storeMatchSMW(match, match2)
	local data = {
		'legacymatch_' .. match2.match2id,
		'is map number=1',
		'has team left=' .. (match.opponent1 or ''),
		'has team right=' .. (match.opponent2 or ''),
		'Has map date=' .. (match.date or ''),
		'Has tournament=' .. mw.title.getCurrentTitle().prefixedText,
		'Has tournament tier=' .. (match.liquipediatier or ''),
		'Has tournament name=' .. Logic.emptyOr(
			match.tickername,
			match.name,
			Variables.varDefault('tournament_name', mw.title.getCurrentTitle().prefixedText)
		),
		'Has tournament icon=' .. Variables.varDefault('tournament_icon', ''),
		'Is riot premier=' .. Variables.varDefault('tournament_riot_premier', ''),
		'Has winner=' .. (match.winner or ''),
		'Has team left score=' .. (match.opponent1score or '0'),
		'Has team right score=' .. (match.opponent2score or '0'),
		'Has exact time=' .. (Logic.readBool(match.dateexact) and 'true' or 'false'),
		'Is finished=' .. (Logic.readBool(match.finished) and 'true' or 'false'),
		'Has teams=' .. (match.opponent1 or ''),
		'Has teams=' .. (match.opponent2 or ''),
	}

	local extradata = Json.parseIfString(match2.extradata) or {}
	local mvp = Json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		for index, player in ipairs(mvp.players) do
			local mvpString = player.name .. '§§§§'.. (player.team or '') ..'§§§§0'
			table.insert(data, 'Has mvp ' .. index .. '=' .. mvpString)
		end
	end

	local streams = match.stream or {}
	streams = Json.parseIfString(streams)
	for key, item in pairs(streams) do
		table.insert(
			data,
			'Has match ' .. key .. '=' .. item
		)
	end

	for key, item in pairs(extradata) do
		if String.startsWith(key, 'vodgame') then
			table.insert(
				data,
				'Has match ' .. key .. '=' .. item
			)
		end
	end

	mw.smw.subobject(data)
end

return MatchLegacy
