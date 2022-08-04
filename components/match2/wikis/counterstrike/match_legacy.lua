---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Opponent = require('Module:Opponent')

local LOSER_STATUSES = {'FF', 'DQ', 'L'}

local MatchLegacy = {}

function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy.convertParameters(match2)

	if options.storeSmw then
		MatchLegacy.storeMatchSMW(match)
	end

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id,
			match
		)
	end
end

function MatchLegacy.convertParameters(match2)
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
	local extradata = Json.parseIfString(match2.extradata)

	local isOverturned = Logic.readBool(extradata.overturned)
	if isOverturned then
		match.walkover = match.winner
		match.resulttype = 'ff'
	end

	match.extradata = {
		timezone = '',
		timezoneID = '',
		matchsection = extradata.matchsection,
		opponent1rounds = 0,
		opponent2rounds = 0,
		overturned = Logic.readBool(extradata.overturned) and '1' or '',
		hidden = Logic.readBool(extradata.hidden) and '1' or '0',
		featured = Logic.readBool(extradata.featured) and '1' or '0',
		icondark = Variables.varDefault('tournament_icon_dark'),
		team1icon = match2.match2opponents[1] and match2.match2opponents[1].icon or nil,
		team2icon = match2.match2opponents[2] and match2.match2opponents[2].icon or nil,
	}

	if extradata.status then
		if extradata.status == 'cancelled' or extradata.status == 'canceled' then
			match.extradata.cancelled = '1'
		else
			match.extradata.cancelled = ''
		end
	end

	local maps = {}
	for gameIndex, game in ipairs(match2.match2games or {}) do
		local scores = ''
		if type(scores) == 'string' then
			scores = Json.parse(game.scores)
		end
		match.extradata.opponent1rounds = match.extradata.opponent1rounds + (tonumber(scores[1] or '') or 0)
		match.extradata.opponent2rounds = match.extradata.opponent2rounds + (tonumber(scores[2] or '') or 0)
		match.extradata['vodgame' .. gameIndex] = game.vod
		table.insert(maps, game.map)
	end
	match.extradata.maps = table.concat(maps, ',')

	if #maps > 0 then
		match.extradata.bestofx = tostring(match2.bestof)
	end

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == Opponent.team then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			--When a match is overturned winner get score needed to win bestofx while loser gets score = 0
			if isOverturned then
				if tonumber(match.winner) == index then
					match[prefix .. 'score'] = math.floor(match2.bestof /2) + 1
				else
					match[prefix .. 'score'] = 0
				end
				match.extradata[prefix .. 'rounds'] = 0
			elseif opponent.status == 'W' then
				match[prefix .. 'score'] = math.floor(match2.bestof /2) + 1
			else
				match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			end

			if Table.includes(LOSER_STATUSES, opponent.status) then
				match.resulttype = opponent.status:lower()
			end

			local opponentplayers = {}
			for i = 1,10 do
				local player = opponentmatch2players[i] or {}
				opponentplayers['p' .. i] = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name or '')
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
			end
			match[prefix .. 'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
		elseif opponent.type == Opponent.solo then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		elseif opponent.type == Opponent.literal then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	match.extradata = mw.ext.LiquipediaDB.lpdb_create_json(match.extradata)

	return match
end

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		-- Extradata
		local extradata = Json.parseIfString(game2.extradata)
		game.extradata = {}

		local opponent1scores, opponent2scores = {}, {}

		if extradata.t1sides and extradata.t2sides and extradata.t1halfs and extradata.t2halfs then
			local t1sides = Json.parseIfString(extradata.t1sides)
			local t2sides = Json.parseIfString(extradata.t2sides)
			local t1halfs = Json.parseIfString(extradata.t1halfs)
			local t2halfs = Json.parseIfString(extradata.t2halfs)

			for index, side in ipairs(t1sides) do
				if math.fmod(index,2) == 1 then
					table.insert(opponent1scores, side)
					table.insert(opponent2scores, t2sides[index])
				end
				table.insert(opponent1scores, t1halfs[index] or 0)
				table.insert(opponent2scores, t2halfs[index] or 0)
			end
		end

		game.extradata.opponent1scores = table.concat(opponent1scores, ',')
		game.extradata.opponent2scores = table.concat(opponent2scores, ',')
		game.extradata = mw.ext.LiquipediaDB.lpdb_create_json(game.extradata)
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

		if game2.walkover == 'ff' or game2.walkover == 'dq' then
			game.walkover = 1
		end

		local res = mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. gameIndex,
			game
		)
		games = games .. res
	end
	return games
end

function MatchLegacy.storeMatchSMW(match)
	mw.smw.subobject({
			['has team left'] = match.opponent1 or '',
			['has team right'] = match.opponent2 or '',
			['has map date'] = match.date or '',
			['has tournament'] = mw.title.getCurrentTitle().prefixedText,
			['has tournament tier'] =  Variables.varDefault('tournament_tier'), -- Legacy support Infobox
			['has tournament tier number'] = match.liquipediatier, -- or this ^
			['has tournament icon'] = Variables.varDefault('tournament_icon'),
			['has tournament name'] = match.tickername,
			['is part of tournament series'] = match.series,
			['has match vod'] = match.vod or '',
			['is major game'] = match.publishertier == 'Major' and 'true' or nil,
			['has tournament valve tier'] = match.publishertier,
			['is finished'] = match.finished == 1 and 'true' or 'false',
			['has team left score'] = match.opponent1score or '0',
			['has team right score'] = match.opponent2score or '0',
			['has exact time'] = Logic.readBool(match.dateexact) and 'true' or 'false',
			['is hidden match'] = Logic.readBool(match.extradata.hidden) and 'true' or 'false'
		}, 'Match_' .. match.opponent1 .. '_vs_' .. match.opponent2 .. '_at_' .. match.date
	)
	mw.smw.subobject({
			['has teams'] = match.opponent1 .. ',' .. match.opponent2, '+sep=,',
			['has teams page'] = match.opponent1 .. ',' .. match.opponent2, '+sep=,',
		}, 'Match_' .. match.opponent1 .. '_vs_' .. match.opponent2 .. '_at_' .. (match.date and match.date or 'TBD')
	)
end

return MatchLegacy