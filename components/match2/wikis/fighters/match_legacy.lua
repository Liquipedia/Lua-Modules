---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Set = require('Module:Set')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


function MatchLegacy.storeMatch(match2, options)
	if not options.storeMatch1 then
		return
	end

	local match = MatchLegacy._convertParameters(match2)

	return mw.ext.LiquipediaDB.lpdb_match('legacymatch_' .. match2.match2id, Json.stringifySubTables(match))
end

function MatchLegacy._convertParameters(match2)
	---@type {[any]: any}
	local match = Table.filterByKey(Table.deepCopy(match2), function (key)
		return not String.startsWith(key, 'match2')
	end)

	if match.walkover == 'FF' or match.walkover == 'DQ' then
		match.resulttype = match.walkover:lower()
		match.walkover = match.winner
	elseif match.walkover == 'L' then
		match.walkover = nil
	end

	match.staticid = match2.match2id
	match.winner = nil

	-- Handle extradata fields
	local extradata = Json.parseIfString(match2.extradata)
	match.extradata = {
		matchsection = extradata.matchsection or '',
	}

	match.shortname = match.tournament
	match.tournament = match.parent

	local bracketData = Json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == 'table' and bracketData.type == 'bracket' and bracketData.inheritedheader then
		match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
	end

	-- Handle Opponents
	local headList = function (participant)
		local heads = Set{}
		Array.forEach(match2.match2games or {}, function(game)
			local participants = Json.parseIfString(game.participants) or {}
			if participants[participant] and participants[participant].characters then
				Array.forEach(
					Array.map(participants[participant].characters, Operator.property('name')),
					FnUtil.curry(heads.add, heads)
				)
			end
		end)
		return heads:toArray()
	end

	local handleOpponent = function(index)
		local prefix = 'opponent' .. index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == Opponent.solo then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix .. 'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix .. 'flag'] = player.flag
			match.extradata[prefix .. 'displayname'] = player.displayname
			match.extradata[prefix .. 'heads'] = table.concat(headList(index .. '_1'), ',')
			if match2.winner == index then
				match.winner = player.name
			end
		elseif opponent.type == Opponent.duo then
			local teamPrefix = 'team' .. index
			match[prefix..'score'] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentPlayers = {}
			for i, player in pairs(opponentmatch2players) do
				local playerPrefix = 'opponent' .. i
				opponentPlayers['p' .. i] = player.name or ''
				match.extradata[teamPrefix .. playerPrefix] = player.name or ''
				match.extradata[teamPrefix .. playerPrefix .. 'flag'] = player.flag or ''
				match.extradata[teamPrefix .. playerPrefix .. 'displayname'] = player.displayname or ''
				match.extradata[teamPrefix .. playerPrefix .. 'heads'] = table.concat(headList(index .. '_' .. i), ',')
			end
			match[prefix..'players'] = mw.ext.LiquipediaDB.lpdb_create_json(opponentPlayers)
			match[prefix] = table.concat(Array.extractValues(opponentPlayers), '/')
			if match2.winner == index then
				match.winner = opponentmatch2players[1].name
			end
		elseif opponent.type == Opponent.literal then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return match
end

return MatchLegacy
