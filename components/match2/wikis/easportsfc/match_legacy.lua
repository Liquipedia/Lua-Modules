---
-- @Liquipedia
-- wiki=easportsfc
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Json = require('Module:Json')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

function MatchLegacy.storeMatch(match2)
	return MatchLegacy.convertParameters(match2)
end

function MatchLegacy.convertParameters(match2)
	---@type table
	local match = Table.filterByKey(match2, function(key) return not String.startsWith(key, 'match2') end)

	local opponents = match2.match2opponents
	if #opponents ~= 2 or opponents[1].type ~= opponents[2].type or
		(opponents[1].type ~= Opponent.solo and opponents[1].type ~= Opponent.team)
	then return nil end

	match.staticid = match2.match2id
	match.extradata = Json.parseIfString(match.extradata) or {}
	match.mode = opponents[1].type

	local handleOpponent = function(opponentIndex)
		local prefix = 'opponent' .. opponentIndex
		local opponent = opponents[opponentIndex]
		local players = opponent.match2players

		match[prefix .. 'score'] = (tonumber(opponent.score) or 0) >= 0 and opponent.score or 0

		if opponent.type == Opponent.tem then
			match[prefix] = String.isNotEmpty(opponent.name) and opponent.name:gsub('_', ' ') or 'TBD'
			return
		end

		--due to above filtering we have opponent.type == Opponent.solo
		local player = players[1] or {}
		match[prefix] = player.name and player.name:gsub('_', ' ') or nil
		match[prefix .. 'flag'] = player.flag
		match.extradata[prefix .. 'name'] = player.displayname
	end

	handleOpponent(1)
	handleOpponent(2)

	if match.resulttype == 'default' then
		match.resulttype = string.upper(match.walkover or '')
		match.walkover = match.winner
	end

	match.extradata.bestof = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	match.extradata = Json.stringify(match.extradata)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

return MatchLegacy
