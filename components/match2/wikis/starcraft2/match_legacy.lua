---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[ToDo:
* Remove temp smw support (after lpdb api is available)
]]--

local MatchLegacy = {}

local json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local _UNKNOWNREASON_DEFAULT_LOSS = 'L'

local MODES = {solo = '1v1', team = 'team'}

function MatchLegacy.storeMatch(match2, options)
	local match, doStore = MatchLegacy.convertParameters(match2)

	if not doStore then
		return
	end

	match.games = MatchLegacy.storeGames(match, match2, options)

	if options.storeSmw then
		if (match2.match2opponents[1] or {}).type == 'team' then
			MatchLegacy.storeTeamMatchSMW(match, match2)
		elseif (match2.match2opponents[1] or {}).type == 'solo' then
			MatchLegacy.storeSoloMatchSMW(match, match2)
		end
	end

	if options.storeMatch1 then
		return mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id,
			match
		)
	end
end

function MatchLegacy.storeGames(match, match2, options)
	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game.extradata = json.parseIfString(game.extradata or '{}') or game.extradata

		if
			game.mode == '1v1' and
			game.extradata.isSubMatch == 'false' and
			game.winner ~= 'skip' and
			game.map ~= 'Definitions'
		then
			game.opponent1 = game.extradata.opponent1
			game.opponent2 = game.extradata.opponent2
			game.date = match.date
			local scores = json.parseIfString(game.scores or '{}') or {}
			game.opponent1score = scores[1] or 0
			game.opponent2score = scores[2] or 0

			game.extradata.winnerrace = game.extradata.winnerfaction
			game.extradata.loserrace = game.extradata.loserfaction

			-- participants holds additional playerdata per match, e.g. the faction (=race)
			-- participants is stored as opponentID_playerID, so e.g. for opponent2, player1 it is '2_1'
			local playerdata = json.parseIfString(game.participants or '{}') or game.participants
			for key, item in pairs(playerdata) do
				local k = mw.text.split(key or '', '_')
				local l = tonumber(k[2])
				k = tonumber(k[1])
				game.extradata['opponent' .. k .. 'race'] = item.faction
				local opp = match2.match2opponents[k] or {}
				local pl = opp.match2players or {}
				game['opponent' .. k .. 'flag'] = (pl[l] or {}).flag
				game.extradata['opponent' .. k .. 'name'] = (pl[l] or {}).displayname
			end
			game.extradata.gamenumber = gameIndex

			game.extradata = json.stringify(game.extradata)
			local res = ''
			if options.storeMatch1 then
				res = mw.ext.LiquipediaDB.lpdb_game(
					'legacygame_' .. match2.match2id .. gameIndex,
					game
				)
			end

			if options.storeSmw then
				MatchLegacy.storeSoloMapSMW(game, gameIndex, match.tournament or '', match2.match2id)
			end

			games = games .. res
		end
	end
	return games
end

function MatchLegacy.convertParameters(match2)
	local doStore = true
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id
	match.extradata = json.parseIfString(match.extradata) or {}
	local opponent1 = match2.match2opponents[1] or {}
	local opponent1match2players = opponent1.match2players or {}
	local opponent2 = match2.match2opponents[2] or {}
	local opponent2match2players = opponent2.match2players or {}

	if opponent1.type == opponent2.type then
		match.mode = MODES[opponent1.type]

		if opponent1.type == 'solo' then
			local player = opponent1match2players[1] or {}
			match.opponent1 = player.name
			match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0 and opponent1.score or 0
			match.opponent1flag = player.flag
			match.extradata.opponent1name = player.displayname
			player.extradata = json.parseIfString(player.extradata or '{}') or player.extradata
			match.extradata.opponent1race = player.extradata.faction
			player = opponent2match2players[1] or {}
			match.opponent2 = player.name
			match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0 and opponent2.score or 0
			match.opponent2flag = player.flag
			match.extradata.opponent2name = player.displayname
			player.extradata = json.parseIfString(player.extradata or '{}') or player.extradata
			match.extradata.opponent2race = player.extradata.faction
		elseif opponent1.type == 'team' then
			match.opponent1 = (opponent1.name or '') ~= '' and opponent1.name or 'TBD'
			match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0 and opponent1.score or 0
			match.opponent2 = (opponent2.name or '') ~= '' and opponent2.name or 'TBD'
			match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0 and opponent2.score or 0
			match.mode = 'team'
		else
			return nil, false
		end

		if match.resulttype == 'default' then
			match.resulttype = string.upper(match.walkover or '')
			if match.resulttype == _UNKNOWNREASON_DEFAULT_LOSS then
				--needs to be converted because in match1 storage it was marked this way
				match.resulttype = 'unk'
			end
			match.walkover = match.winner
		end
		match.extradata.bestof = match2.bestof ~= 0 and tostring(match2.bestof) or ''
		match.extradata = json.stringify(match.extradata)
	else
		doStore = false
		match = nil
	end

	return match, doStore
end

function MatchLegacy.storeTeamMatchSMW(match, match2)
	local streams = match.stream or {}
	if type(streams) == 'string' then streams = json.parse(streams) end
	local extradata = match.extradata or {}
	if type(extradata) == 'string' then extradata = json.parse(extradata) end
	mw.smw.subobject({
		'legacymatch_' .. match2.match2id,
		'has match vod=' .. (match.vod or ''),
		'has team left page=' .. (match.opponent1 or ''),
		'has team right page=' .. (match.opponent2 or ''),
		'has team left=' .. string.lower(match2.match2opponents[1].template or ''),
		'has team right=' .. string.lower(match2.match2opponents[2].template or ''),
		--apparently needed for sorting ...
		'has player left page=' .. (match.opponent1 or ''),
		'has player right page=' .. (match.opponent2 or ''),
		'has match date=' .. (match.date or ''),
		'has tournament=' .. (match.tournament or ''),
		'has tournament tier=' .. (match.liquipediatier or ''),
		'is finished=' .. (match.finished == '1' and 'true' or ''),
		'has winner=' .. (match.winner or ''),
		'has winning team page=' ..
			(match.winner == '1' and match.opponent1 or match.winner == '2' and match.opponent2 or ''),
		'has losing team page=' ..
			(match.winner == '2' and match.opponent1 or match.winner == '1' and match.opponent2 or ''),
		'has team left score=' .. (match2.match2opponents[1].score or ''),
		'has team right score=' .. (match2.match2opponents[2].score or ''),
		'has exact time=' .. (match.dateexact == '1' and 'true' or ''),
		'has match stream=' .. (streams.stream or ''),
		'has match twitch=' .. (streams.twitch or ''),
		'has match twitch2=' .. (streams.twitch2 or ''),
		'has match trovo=' .. (streams.trovo or ''),
		'has match afreeca=' .. (streams.afreeca or ''),
		'has match afreecatv=' .. (streams.afreecatv or ''),
		'has match dailymotion=' .. (streams.dailymotion or ''),
		'has match douyu=' .. (streams.douyu or ''),
		'has match youtube=' .. (streams.youtube or ''),
		'has best of=' .. (extradata.bestof or ''),
	})
end

function MatchLegacy.storeSoloMatchSMW(match, match2)
	local streams = match.stream or {}
	if type(streams) == 'string' then streams = json.parse(streams) end
	local extradata = match.extradata or {}
	if type(extradata) == 'string' then extradata = json.parse(extradata) end
	mw.smw.subobject({
		'legacymatch_' .. match2.match2id,
		'has match vod=' .. (match.vod or ''),
		'has player left=' .. extradata.opponent1name,
		'has player right=' .. extradata.opponent2name,
		'has player left page=' .. (match.opponent1 or ''),
		'has player right page=' .. (match.opponent2 or ''),
		'has player left flag=' .. match.opponent1flag,
		'has player right flag=' .. match.opponent2flag,
		'has player left race=' .. extradata.opponent1race,
		'has player right race=' .. extradata.opponent2race,
		'has match date=' .. (match.date or ''),
		'has tournament=' .. (match.tournament or ''),
		'has tournament tier=' .. (match.liquipediatier or ''),
		'is finished=' .. (match.finished == '1' and 'true' or ''),
		'has winner=' .. (match.winner or ''),
		'has player left score=' .. (match2.match2opponents[1].score or ''),
		'has player right score=' .. (match2.match2opponents[2].score or ''),
		'has exact time=' .. (match.dateexact == '1' and 'true' or ''),
		'has match stream=' .. (streams.stream or ''),
		'has match twitch=' .. (streams.twitch or ''),
		'has match twitch2=' .. (streams.twitch2 or ''),
		'has match trovo=' .. (streams.trovo or ''),
		'has match afreeca=' .. (streams.afreeca or ''),
		'has match afreecatv=' .. (streams.afreecatv or ''),
		'has match dailymotion=' .. (streams.dailymotion or ''),
		'has match douyu=' .. (streams.douyu or ''),
		'has match youtube=' .. (streams.youtube or ''),
		'has best of=' .. (extradata.bestof or ''),
	})
end

function MatchLegacy.storeSoloMapSMW(game, gameIndex, tournament, id)
	game.extradata = json.parseIfString(game.extradata or '{}') or game.extradata
	local object = 'Map ' .. (game.opponent1 or 'TBD') .. ' vs ' .. (game.opponent2 or 'TBD') .. ' at ' ..
		(game.date or '') .. 'in Match TBD Map ' .. gameIndex .. ' on ' .. (game.map or '')
	mw.smw.subobject({
		'legacymatch_' .. id .. object,
		'has winning race=' .. (game.extradata.winnerrace or ''),
		'has losing race=' .. (game.extradata.loserrace or ''),
		'has tournament=' .. (tournament or ''),
		'is played on=' .. (game.map or ''),
	})
end

return MatchLegacy
