---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy._convertParameters(match2)

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			'legacymatch_' .. match2.match2id,
			match
		)
	end
end

function MatchLegacy.storeGames(match, match2)
	local games = ''
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		local scores = game2.scores or {}
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
	
	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' then
		if bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
	end

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = 'opponent'..index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == Opponent.team then
			match[prefix] = opponent.name
			match[prefix..'score'] = tonumber(opponent.score) or 0 >= 0 and opponent.score or 0
			local opponentplayers = {}
			for i = 1, 10 do
				local player = opponentmatch2players[i] or {}
				opponentplayers['p' .. i] = player.name or ''
				opponentplayers['p' .. i .. 'flag'] = player.flag or ''
				opponentplayers['p' .. i .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = opponentplayers
		elseif opponent.type == Opponent.solo then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix..'score'] = tonumber(opponent.score) or 0 >= 0 and opponent.score or 0
			match[prefix..'flag'] = player.flag
		elseif opponent.type == Opponent.literal then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

return MatchLegacy
