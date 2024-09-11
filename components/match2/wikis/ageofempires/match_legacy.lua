---
-- @Liquipedia
-- wiki=ageofempires
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
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	match.games = MatchLegacy.storeGames(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match('legacymatch_' .. match2.match2id, Json.stringifySubTables(match))
end

function MatchLegacy.storeGames(match, match2)
	local games = {}
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		local participants = Json.parseIfString(game2.participants) or {}

		-- Extradata
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		game.extradata.mapmode = game2.extradata.mapmode
		game.extradata.tournament = match.tournament
		game.extradata.vodmatch = match.vod
		if game.mode == 'team' then
			local function processOpponent(opponentIndex)
				for _, player, playerId in Table.iter.pairsByPrefix(participants, opponentIndex .. '_') do
					local prefix = 'o' .. opponentIndex .. 'p' .. playerId
					game.extradata[prefix] = player.pageName
					game.extradata[prefix .. 'faction'] = player.civ
					game.extradata[prefix .. 'name'] = player.displayname
					game.extradata[prefix .. 'flag'] = player.flag
				end
			end
			processOpponent(1)
			processOpponent(2)
		elseif game.mode == '1v1' then
			local player1 = participants['1_1'] or {}
			local player2 = participants['2_1'] or {}
			game.extradata.opponent1civ = player1.civ
			game.extradata.opponent2civ = player2.civ
			game.extradata.winnerciv =
					(tonumber(game.winner) == 1 and game.extradata.opponent1civ) or
					(tonumber(game.winner) == 2 and game.extradata.opponent2civ) or
					''
			game.extradata.loserciv =
					(tonumber(game.winner) == 2 and game.extradata.opponent1civ) or
					(tonumber(game.winner) == 1 and game.extradata.opponent2civ) or
					''
			game.extradata.opponent1name = player1.player
			game.extradata.opponent2name = player2.player
		end
		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag

		local scores = Json.parseIfString(game2.scores) or {}
		game.opponent1score = scores[1] or 0
		game.opponent2score = scores[2] or 0
		local res = mw.ext.LiquipediaDB.lpdb_game(
			'legacygame_' .. match2.match2id .. gameIndex,
			Json.stringifySubTables(game)
		)
		table.insert(games, res)
	end
	return table.concat(games)
end

function MatchLegacy._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.walkover = match.walkover and string.upper(match.walkover) or nil
	if match.walkover == 'FF' or match.walkover == 'DQ' then
		match.resulttype = match.walkover:lower()
		match.walkover = match.winner
	elseif match.walkover == 'L' then
		match.walkover = nil
	end

	match.staticid = match2.match2id

	local extradata = Json.parseIfString(match2.extradata)
	-- Handle extradata fields
	match.extradata = {
		matchsection = extradata.matchsection or '',
	}

	match.extradata.bestof = (match2.bestof and match2.bestof ~= 0) and tostring(match2.bestof) or ''
	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' and bracketData.inheritedheader then
		match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
	end
	match.extradata.matchround = match.header

	-- Handle Opponents
	local handleOpponent = function(index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == Opponent.solo then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name:gsub(' ', '_')
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
			match.extradata[prefix .. 'name'] = player.displayname
		elseif opponent.type == Opponent.team then
			match[prefix] = mw.ext.TeamTemplate.raw(opponent.template).page
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for i, player in pairs(opponentmatch2players) do
				opponentplayers['p' .. i] = player.name or ''
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
		elseif opponent.type == Opponent.literal then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	local games = match2.match2games or {}
	for key, game in ipairs(games) do
		if String.isNotEmpty(game.vod) then
			match.extradata['vodgame' .. key] = game.vod
		end
	end

	return match
end

return MatchLegacy
