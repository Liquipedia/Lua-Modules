---
-- @Liquipedia
-- wiki=rainbowsix
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
		-- Extradata
		local extradata = Json.parseIfString(game2.extradata)
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		if extradata.t1bans and extradata.t2bans then
			game.extradata.opponent1bans = table.concat(Json.parseIfString(extradata.t1bans), ', ')
			game.extradata.opponent2bans = table.concat(Json.parseIfString(extradata.t2bans), ', ')
		end
		if extradata.t1firstside and extradata.t1halfs and extradata.t2halfs then
			extradata.t1firstside = Json.parseIfString(extradata.t1firstside)
			extradata.t1halfs = Json.parseIfString(extradata.t1halfs)
			extradata.t2halfs = Json.parseIfString(extradata.t2halfs)
			local team1 = {}
			local team2 = {}
			if extradata.t1firstside.rt == 'atk' then
				team1 = {'atk', extradata.t1halfs.atk or 0, extradata.t1halfs.def or 0}
				team2 = {'def', extradata.t2halfs.atk or 0, extradata.t2halfs.def or 0}
			elseif extradata.t1firstside.rt == 'def' then
				team2 = {'atk', extradata.t2halfs.atk or 0, extradata.t2halfs.def or 0}
				team1 = {'def', extradata.t1halfs.atk or 0, extradata.t1halfs.def or 0}
			end
			if extradata.t1firstside.ot == 'atk' then
				table.insert(team1, 'atk')
				table.insert(team1, extradata.t1halfs.otatk or 0)
				table.insert(team1, extradata.t1halfs.otdef or 0)
				table.insert(team2, 'def')
				table.insert(team2, extradata.t2halfs.otatk or 0)
				table.insert(team2, extradata.t2halfs.otdef or 0)
			elseif extradata.t1firstside.ot == 'def' then
				table.insert(team2, 'atk')
				table.insert(team2, extradata.t2halfs.otatk or 0)
				table.insert(team2, extradata.t2halfs.otdef or 0)
				table.insert(team1, 'def')
				table.insert(team1, extradata.t1halfs.otatk or 0)
				table.insert(team1, extradata.t1halfs.otdef or 0)
			end
			game.extradata.opponent1scores = table.concat(team1, ', ')
			game.extradata.opponent2scores = table.concat(team2, ', ')
		end
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
			Json.stringifySubTables(game)
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
	local extradata = Json.parseIfString(match2.extradata)

	match.extradata.matchsection = extradata.matchsection
	match.extradata.bestofx = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' then
		if bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
	end

	local veto = Json.parseIfString(extradata.mapveto)
	if veto then
		for k, round in ipairs(veto) do
			if k == 1 then
				match.extradata.firstban = round.vetostart
			end
			if not round.type then break end
			if round.team1 or round.decider then
				match.extradata['opponent1mapban'..k] = (round.team1 or round.decider) .. ',' .. round.type
			end
			if round.team2 then
				match.extradata['opponent2mapban'..k] = round.team2 .. ',' .. round.type
			end
		end
	end

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
				opponentplayers['p' .. i] = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name or '')
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = opponentplayers
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

	return Json.stringifySubTables(match)
end

return MatchLegacy
