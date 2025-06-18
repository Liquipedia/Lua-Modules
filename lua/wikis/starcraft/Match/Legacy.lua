---
-- @Liquipedia
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local MatchLegacyUtil = Lua.import('Module:MatchGroup/Legacy/Util')

local _MODES = {solo = '1v1', team = 'team'}

function MatchLegacy.storeMatch(match2)
	local match, doStore = MatchLegacy._convertParameters(match2)

	if not doStore then
		return
	end

	match.games = MatchLegacy._storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy._storeGames(match, match2)
	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game.extradata = Json.parseIfString(game.extradata or '{}') or game.extradata
		local opponents = Json.parseIfString(game.opponents) or {}
		local scores = Array.map(opponents, Operator.property('score'))

		if game.mode == '1v1' then
			game.opponent1 = game.extradata.opponent1
			game.opponent2 = game.extradata.opponent2
			game.date = match.date
			game.opponent1score = scores[1] or 0
			game.opponent2score = scores[2] or 0

			game.extradata.winnerrace = game.extradata.winnerfaction
			game.extradata.loserrace = game.extradata.loserfaction

			Array.forEach(opponents, function(opponent, opponentIndex)
				Array.forEach(opponent.players or {}, function(player, playerIndex)
					if Logic.isDeepEmpty(player) then return end
					local matchPlayer = match2.match2opponents[opponentIndex].match2players[playerIndex] or {}
					game.extradata['opponent' .. opponentIndex .. 'race'] = player.faction
					game['opponent' .. opponentIndex .. 'flag'] = matchPlayer.flag
					game.extradata['opponent' .. opponentIndex .. 'name'] = matchPlayer.displayname
					game.extradata['tournament'] = match2.tournament or ''
					game.extradata['series'] = match2.series or ''
				end)
			end)

			game.extradata.gamenumber = gameIndex

			game.extradata = Json.stringify(game.extradata)
			local res = mw.ext.LiquipediaDB.lpdb_game(
					'legacygame_' .. match2.match2id .. gameIndex,
					game
				)

			games = games .. res
		elseif	game.mode == '1v1' then
			local submatch = {}

			submatch.opponent1 = game.extradata.opponent1
			submatch.opponent2 = game.extradata.opponent2
			submatch.opponent1score = scores[1] or 0
			submatch.opponent2score = scores[2] or 0
			submatch.extradata = {}

			Array.forEach(opponents, function(opponent, opponentIndex)
				Array.forEach(opponent.players or {}, function(player, playerIndex)
					if Logic.isDeepEmpty(player) then return end
					local matchPlayer = match2.match2opponents[opponentIndex].match2players[playerIndex] or {}
					submatch.extradata['opponent' .. opponentIndex .. 'race'] = player.faction
					submatch['opponent' .. opponentIndex .. 'flag'] = matchPlayer.flag
					submatch.extradata['opponent' .. opponentIndex .. 'name'] = matchPlayer.displayname
				end)
			end)

			submatch.winner = game.winner or ''
			local walkover = MatchLegacyUtil.calculateWalkoverType(opponents)
			submatch.walkover = (walkover or ''):lower()
			submatch.finished = match2.finished or '0'
			submatch.mode = '1v1'
			submatch.date = game.date
			submatch.dateexact = match2.dateexact or ''
			submatch.stream = match2.stream
			submatch.vod = game.vod
			submatch.tournament = match2.tournament
			submatch.tickername = match2.tickername
			submatch.shortname = match2.shortname
			submatch.series = match2.series
			submatch.icon = match2.icon
			submatch.liquipediatier = match2.liquipediatier
			submatch.type = match2.type
			submatch.game = match2.game
			submatch.extradata = Json.stringify(submatch.extradata --[[@as table]])

			mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id .. gameIndex,
			submatch
		)
		end
	end
	return games
end

function MatchLegacy._convertParameters(match2)
	local doStore = true
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id
	match.extradata = Json.parseIfString(match.extradata) or {}
	local opponent1 = match2.match2opponents[1] or {}
	local opponent1match2players = opponent1.match2players or {}
	local opponent2 = match2.match2opponents[2] or {}
	local opponent2match2players = opponent2.match2players or {}

	if opponent1.type == opponent2.type then
		match.mode = _MODES[opponent1.type]

		if opponent1.type == 'solo' then
			local player = opponent1match2players[1] or {}
			match.opponent1 = player.name
			match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0 and opponent1.score or 0
			match.opponent1flag = player.flag
			match.extradata.opponent1name = player.displayname
			player.extradata = Json.parseIfString(player.extradata or '{}') or player.extradata
			match.extradata.opponent1race = player.extradata.faction
			player = opponent2match2players[1] or {}
			match.opponent2 = player.name
			match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0 and opponent2.score or 0
			match.opponent2flag = player.flag
			match.extradata.opponent2name = player.displayname
			player.extradata = Json.parseIfString(player.extradata or '{}') or player.extradata
			match.extradata.opponent2race = player.extradata.faction
		elseif opponent1.type == 'team' then
			match.opponent1 = Template.safeExpand(
				mw.getCurrentFrame(),
				'TeamPage',
				{(opponent1.name or '') ~= '' and opponent1.name or 'TBD'}
			)
			match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0 and opponent1.score or 0
			match.opponent2 = Template.safeExpand(
				mw.getCurrentFrame(),
				'TeamPage',
				{(opponent2.name or '') ~= '' and opponent2.name or 'TBD'}
			)
			match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0 and opponent2.score or 0
			match.mode = 'team'
		else
			return nil, false
		end

		local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
		if walkover then
			match.resulttype = walkover
			match.walkover = match.winner
		end
		match.extradata.bestof = match2.bestof ~= 0 and tostring(match2.bestof) or ''
		match.extradata = Json.stringify(match.extradata)
	else
		return nil, false
	end

	return match, doStore
end

return MatchLegacy
