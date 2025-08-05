---
-- @Liquipedia
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchLegacyUtil = Lua.import('Module:MatchGroup/Legacy/Util')

function MatchLegacy.storeMatch(match2)
	local match = MatchLegacy._convertParameters(match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

function MatchLegacy._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	local walkover = MatchLegacyUtil.calculateWalkoverType(match2.match2opponents)
	match.walkover = walkover and walkover:lower() or nil
	if match.walkover == 'ff' or match.walkover == 'dq' then
		match.walkover = match.winner
	elseif match.walkover == 'l' then
		match.walkover = nil
	end

	match.staticid = match2.match2id

		-- Handle Opponents
	local handleOpponent = function (opponentIndex)
		local prefix = 'opponent'..opponentIndex
		local opponent = match2.match2opponents[opponentIndex] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == 'team' then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for playerIndex = 1, 10 do
				local player = opponentmatch2players[playerIndex] or {}
				opponentplayers['p' .. playerIndex] = mw.ext.TeamLiquidIntegration.resolve_redirect(player.name or '')
				opponentplayers['p' .. playerIndex .. 'flag'] = player.flag or ''
				opponentplayers['p' .. playerIndex .. 'dn'] = player.displayname or ''
			end
			match[prefix..'players'] = opponentplayers
		elseif opponent.type == 'solo' then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
		elseif opponent.type == 'literal' then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return Json.stringifySubTables(match)
end

return MatchLegacy
