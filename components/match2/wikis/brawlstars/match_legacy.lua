---
-- @Liquipedia
-- wiki=brawlstars
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

function MatchLegacy.storeMatchSMW(match, match2)
	local streams = Json.parseIfString(match.stream or {})
	local icon = Variables.varDefault('tournament_icon')
	local opponents = match2.match2opponents

	local subObjectTable = {
		'legacymatch_' .. match2.match2id,
		'has team left=' .. (match.opponent1 or ''),
		'has team left template name=' .. (opponents[1].template or ''),
		'Has team left score=' .. (match.opponent1score or '0'),
		'has team right=' .. (match.opponent2 or ''),
		'has team right template name=' .. (opponents[2].template or ''),
		'Has team right score=' .. (match.opponent2score or '0'),
		'Has match vod=' .. (match2.vod or ''),
		'Has tournament=' .. mw.title.getCurrentTitle().prefixedText,
		'Has tournament tier=' .. (match.liquipediatier or ''),
		'Has tournament name=' .. Logic.emptyOr(match.tickername, match.name, ''),
		'Has tournament icon=' .. (icon or ''),
		'Is finished=' .. (Logic.readBool(match.finished) and 'true' or 'false'),
		'Has exact time=' .. (Logic.readBool(match.dateexact) and 'true' or 'false'),
		'Is hidden match=0',
		'Has map date=' .. (match.date or ''),
		'Has winner=' .. (match.winner or ''),
		'Has special ticker name' .. Variables.varDefault('special_ticker_name', ''),
		'Is part of tournament series' .. Variables.varDefault('tournament_series', ''),
		'Is featured match' .. Variables.varDefault('match_featured', ''),
		'Is major game' .. Variables.varDefault('tournament_valve_major', ''),
		'Is major game' .. Variables.varDefault('tournament_valve_major', ''),
		'Has tournament valve tier' .. Variables.varDefault('tournament_valve_tier', ''),

		'Has teams=' .. (match.opponent1 or ''),
		'Has teams=' .. (match.opponent2 or ''),
		'Has teams name=' .. (match.opponent1 or ''),
		'Has teams name=' .. (match.opponent2 or ''),
		'has teams page=' .. mw.ext.TeamLiquidIntegration.resolve_redirect(match.opponent1 or ''),
		'has teams page=' .. mw.ext.TeamLiquidIntegration.resolve_redirect(match.opponent2 or ''),
	}

	for key, item in pairs(streams) do
		table.insert(
			subObjectTable,
			'Has match ' .. key .. '=' .. item
		)
	end

	for key, map in pairs(match2.match2games) do
		table.insert(
			subObjectTable,
			'Has match vodgame' .. key .. '=' .. (map.vod or '')
		)
	end

--[[
|has teams page={{#resolve_redirect:{{#var:team1|TBD}}}},{{#resolve_redirect:{{#var:team2|TBD}}}}|+sep=,
]]

	mw.smw.subobject(subObjectTable)
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
	local extradata = Json.parseIfString(match2.extradata)
	match.extradata = {
		mvp = extradata.mvp,
	}

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
			match[prefix .. 'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
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

	match.extradata = mw.ext.LiquipediaDB.lpdb_create_json(match.extradata)

	return match
end

return MatchLegacy
