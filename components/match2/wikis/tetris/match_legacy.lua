---
-- @Liquipedia
-- wiki=tetris
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

function MatchLegacy.storeMatch(match2)
	return MatchLegacy.convertParameters(match2)
end

function MatchLegacy.convertParameters(match2)
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
		match.mode = opponent1.type

		if opponent1.type == 'solo' then
			local player = opponent1match2players[1] or {}
			match.opponent1 = player.name and player.name:gsub('_', ' ') or nil
			match.opponent1score = (tonumber(opponent1.score) or 0) > 0 and opponent1.score or 0
			match.opponent1flag = player.flag
			match.extradata.opponent1name = player.displayname
			player.extradata = Json.parseIfString(player.extradata or '{}') or player.extradata
			player = opponent2match2players[1] or {}
			match.opponent2 = player.name and player.name:gsub('_', ' ') or nil
			match.opponent2score = (tonumber(opponent2.score) or 0) > 0 and opponent2.score or 0
			match.opponent2flag = player.flag
			match.extradata.opponent2name = player.displayname
			player.extradata = Json.parseIfString(player.extradata or '{}') or player.extradata
		elseif opponent1.type == 'team' then
			match.opponent1 = String.isNotEmpty(opponent1.name) and opponent1.name:gsub('_', ' ') or 'TBD'
			match.opponent1score = (tonumber(opponent1.score) or 0) > 0 and opponent1.score or 0
			match.opponent2 = String.isNotEmpty(opponent2.name) and opponent2.name:gsub('_', ' ') or 'TBD'
			match.opponent2score = (tonumber(opponent2.score) or 0) > 0 and opponent2.score or 0
			match.mode = 'team'
		else
			return nil
		end

		if match.resulttype == 'default' then
			match.resulttype = string.upper(match.walkover or '')
			match.walkover = match.winner
		end
		match.extradata.bestof = match2.bestof ~= 0 and tostring(match2.bestof) or ''
		match.extradata = Json.stringify(match.extradata)
	else
		return nil
	end

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

return MatchLegacy
