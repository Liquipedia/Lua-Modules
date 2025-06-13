---
-- @Liquipedia
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchLegacyUtil = Lua.import('Module:MatchGroup/Legacy/Util')

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
		local opponents = Json.parseIfString(game2.opponents) or {}
		local scores = Array.map(opponents, Operator.property('score'))
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		if extradata then
			if extradata.t1firstside and extradata.t1halfs and extradata.t2halfs then
				local firstSide = extradata.t1firstside
				local team1Halfs = Json.parseIfString(extradata.t1halfs)
				local team2Halfs = Json.parseIfString(extradata.t2halfs)
				local hasOvertime = team1Halfs.otatk or team1Halfs.otdef or team2Halfs.otatk or team2Halfs.otdef
				local team1 = {}
				local team2 = {}
				if firstSide == 'atk' then
					team1 = {'atk', team1Halfs.atk or 0, team1Halfs.def or 0}
					team2 = {'def', team2Halfs.atk or 0, team2Halfs.def or 0}
				elseif firstSide == 'def' then
					team2 = {'atk', team2Halfs.atk or 0, team2Halfs.def or 0}
					team1 = {'def', team1Halfs.atk or 0, team1Halfs.def or 0}
				end
				if hasOvertime then
					if firstSide == 'atk' then
						table.insert(team1, 'atk')
						table.insert(team1, team1Halfs.otatk or 0)
						table.insert(team1, team1Halfs.otdef or 0)
						table.insert(team2, 'def')
						table.insert(team2, team2Halfs.otatk or 0)
						table.insert(team2, team2Halfs.otdef or 0)
					elseif firstSide == 'def' then
						table.insert(team2, 'atk')
						table.insert(team2, team2Halfs.otatk or 0)
						table.insert(team2, team2Halfs.otdef or 0)
						table.insert(team1, 'def')
						table.insert(team1, team1Halfs.otatk or 0)
						table.insert(team1, team1Halfs.otdef or 0)
					end
				end
				game.extradata.opponent1scores = table.concat(team1, ', ')
				game.extradata.opponent2scores = table.concat(team2, ', ')
			end
		end
		local addPlayer = function (teamId, playerId, data)
			if data then
				local playerPage = data.player and mw.ext.TeamLiquidIntegration.resolve_redirect(data.player) or ''
				game.extradata['t' .. teamId .. 'p' .. playerId] = playerPage
				if data.kills and data.deaths and data.assists then
					game.extradata['t' .. teamId .. 'kda' .. playerId] = data.kills .. '/' .. data.deaths .. '/' .. data.assists
				end
				game.extradata['t' .. teamId .. 'acs' .. playerId] = data.acs
				game.extradata['t' .. teamId .. 'a' .. playerId] = data.agent
			end
		end
		for teamId, opponent in ipairs(opponents) do
			local counter = 0
			for _, player in pairs(opponent.players) do
				if Logic.isNotEmpty(player) then
					counter = counter + 1
					addPlayer(teamId, counter, player)
				end
			end
		end
		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date

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

	local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
	match.resulttype = walkover and walkover:lower() or nil
	if walkover == 'FF' or match.walkover == 'DQ' then
		match.walkover = match.winner
	elseif walkover == 'L' then
		match.walkover = nil
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = Json.parseIfString(match2.extradata)

	match.extradata.matchsection = extradata.matchsection
	match.extradata.gamechangers = Variables.varDefault('gamechangers')
	match.extradata.hidden = Logic.readBool(Variables.varDefault('match_hidden')) and '1' or '0'
	match.extradata.cancelled = Logic.readBool(Variables.varDefault('cancelled')) and '1' or '0'
	match.extradata.bestofx = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	match.extradata.maps = table.concat(MatchLegacy._getAllInGames(match2, 'map'), ',')
	for index, vod in ipairs(MatchLegacy._getAllInGames(match2, 'vod')) do
		match.extradata['vodgame'..index] = vod
	end

	local opponent1score = 0
	local opponent2score = 0
	local scores = Array.map(match2.match2games or {}, function(game)
		local opponents = Json.parseIfString(game.opponents) or {}
		return Array.map(opponents, Operator.property('score'))
	end)
	for _, score in pairs(scores) do
		opponent1score = opponent1score + (tonumber(score[1]) or 0)
		opponent2score = opponent2score + (tonumber(score[2]) or 0)
	end
	match.extradata.opponent1rounds = opponent1score
	match.extradata.opponent2rounds = opponent2score

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
		if opponent.type == 'team' then
			match[prefix] = opponent.name
			if match2.bestof == 1 and scores[1] then
				match[prefix .. 'score'] = scores[1][index]
			end
			if not match[prefix..'score'] then
				match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			end
			local players = {}
			Array.forEach(opponent.match2players or {}, function(player, playerIndex)
				players['p' .. playerIndex] = player.name or ''
				players['p' .. playerIndex .. 'flag'] = player.flag or ''
				players['p' .. playerIndex .. 'dn'] = player.displayname or ''
			end)
			match[prefix .. 'players'] = players
		elseif opponent.type == 'solo' then
			local player = (opponent.match2players or {})[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = tonumber(opponent.score) or 0 >= 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		elseif opponent.type == 'literal' then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

function MatchLegacy._getAllInGames(match2, field)
	local ret = {}
	for _, game2 in ipairs(match2.match2games or {}) do
		table.insert(ret, game2[field])
	end
	return ret
end

return MatchLegacy
