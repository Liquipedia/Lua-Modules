---
-- @Liquipedia
-- wiki=zula
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TextSanitizer = require('Module:TextSanitizer')

local Opponent = Lua.import('Module:Opponent')

local DRAW = 'draw'
local LOSER_STATUSES = {'FF', 'DQ', 'L'}

local MatchLegacy = {}

function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy.convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy.convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	if match.resulttype == DRAW then
		match.winner = 'draw'
	end

	match.resulttype = nil

	if match.walkover == 'ff' or match.walkover == 'dq' then
		match.walkover = match.winner
	else
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
		timezone = extradata.timezoneoffset or '',
		timezoneID = extradata.timezoneid or '',
		matchsection = extradata.matchsection or '',
		bestofx = match2.bestof ~= 0 and tostring(match2.bestof) or '',
		overturned = Logic.readBool(extradata.overturned) and '1' or '',
		hidden = Logic.readBool(extradata.hidden) and '1' or '0',
		featured = Logic.readBool(extradata.featured) and '1' or '0',
		cancelled = '',
		icondark = match2.icondark,
		team1icon = match2.match2opponents[1] and match2.match2opponents[1].icon or nil,
		team2icon = match2.match2opponents[2] and match2.match2opponents[2].icon or nil,
	}

	if extradata.status then
		if extradata.status == 'cancelled' or extradata.status == 'canceled' then
			match.extradata.cancelled = '1'
		end
	end

	local opponent1Rounds, opponent2Rounds = 0, 0
	local maps = {}
	for gameIndex, game in ipairs(match2.match2games or {}) do
		local scores = game.scores or {}
		if type(scores) == 'string' then
			scores = Json.parse(game.scores)
		end
		opponent1Rounds = opponent1Rounds + (tonumber(scores[1] or '') or 0)
		opponent2Rounds = opponent2Rounds + (tonumber(scores[2] or '') or 0)
		match.extradata['vodgame' .. gameIndex] = game.vod
		table.insert(maps, game.map)
	end
	match.extradata.opponent1rounds = tostring(opponent1Rounds)
	match.extradata.opponent2rounds = tostring(opponent2Rounds)
	match.extradata.maps = table.concat(maps, ',')

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == Opponent.team or opponent.type == Opponent.literal then
			if opponent.type == Opponent.team then
				if String.isEmpty(opponent.template) then
					match[prefix] = 'TBD'
				elseif mw.ext.TeamTemplate.teamexists(opponent.template) then
					match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
				else
					match[prefix] = opponent.template
				end
			else
				if String.isEmpty(opponent.name) or TextSanitizer.stripHTML(opponent.name) ~= opponent.name then
					match[prefix] = 'TBD'
				else
					match[prefix] = opponent.name
				end
			end
			--When a match is overturned winner get score needed to win bestofx while loser gets score = 0
			if isOverturned then
				match[prefix .. 'score'] = tonumber(match.winner) == index and (math.floor(match2.bestof /2) + 1) or 0
				match.extradata[prefix .. 'rounds'] = '0'
			elseif opponent.status == 'W' then
				match[prefix .. 'score'] = math.floor(match2.bestof /2) + 1
			else
				if match2.bestof == 1 then
					if match.winner == DRAW then
						match[prefix .. 'score'] = 0
					else
						match[prefix .. 'score'] = tonumber(match.winner) == index and 1 or 0
					end
				else
					match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
				end
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
			match[prefix .. 'players'] = opponentplayers
		elseif opponent.type == Opponent.solo then
			if String.isEmpty(opponent.name) then
				match[prefix] = 'TBD'
			else
				local player = opponentmatch2players[1] or {}
				match[prefix] = player.name
				match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
				match[prefix .. 'flag'] = player.flag
			end
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
			Json.stringifySubTables(game)
		)
		games = games .. res
	end
	return games
end

return MatchLegacy
