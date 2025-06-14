---
-- @Liquipedia
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
	return MatchLegacy.store(match2)
end

function MatchLegacy.store(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, 'match2') then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id
	match.extradata = Json.parseIfString(match.extradata) or {}
	local opponent1 = match2.match2opponents[1] or {}
	local opponent2 = match2.match2opponents[2] or {}

	if opponent1.type ~= opponent2.type then
		return
	end
	match.mode = opponent1.type

	local getScore = function(score)
		return (tonumber(score) or 0) >= 0 and score or 0
	end

	if opponent1.type == Opponent.solo then
		local function handlePlayer(index)
			local opponent = match2.match2opponents[index] or {}
			local player = opponent.match2players[1] or {}
			local prefix = 'opponent' .. index

			match[prefix] = player.name and player.name:gsub('_', ' ') or nil
			match[prefix .. 'score'] = getScore(opponent.score)
			match[prefix .. 'flag'] = player.flag
			match.extradata[prefix .. 'name'] = player.displayname
			player.extradata = Json.parseIfString(player.extradata) or {}
		end
		handlePlayer(1)
		handlePlayer(2)
	elseif opponent1.type == Opponent.team then
		match.opponent1 = String.isNotEmpty(opponent1.name) and opponent1.name:gsub('_', ' ') or 'TBD'
		match.opponent1score = getScore(opponent1.score)

		match.opponent2 = String.isNotEmpty(opponent2.name) and opponent2.name:gsub('_', ' ') or 'TBD'
		match.opponent2score = getScore(opponent2.score)
	else
		return
	end

	match.extradata.bestof = match2.bestof ~= 0 and tostring(match2.bestof) or ''
	match.extradata = Json.stringify(match.extradata)

	return mw.ext.LiquipediaDB.lpdb_match(
		'legacymatch_' .. match2.match2id,
		match
	)
end

return MatchLegacy
