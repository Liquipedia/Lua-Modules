---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local CustomMatchGroupInputBigMatch = {}

local ROLE_ORDER = Table.map({
	'top',
	'jungle',
	'middle',
	'bottom',
	'support',
}, function(idx, value)
	return value, idx
end)

function CustomMatchGroupInputBigMatch.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.LeagueOfLegendsDB.getData(mapInput.matchid, Logic.readBool(mapInput.reversed))
	-- Match not found on the API
	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')

	return map
end

function CustomMatchGroupInputBigMatch.getLength(map)
	if not map.length then
		return
	end
	-- Convert seconds to minutes and seconds
	return math.floor(map.length / 60) .. ':' .. string.format('%02d', map.length % 60)
end

function CustomMatchGroupInputBigMatch.getSide(map, opponentIndex)
	return (map['team' .. opponentIndex] or {}).color
end

function CustomMatchGroupInputBigMatch.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	if not team.players then return end
	local players = Array.map(team.players, function(player)
		return {
			name = player.name,
			role = player.role,
			character = player.champion,
			gold = player.gold,
			kills = player.kills,
			deaths = player.deaths,
			assists = player.assists,
			damagedone = player.damageDone,
			creepscore = player.creepScore,
			items = player.items,
			runes = player.runeData,
		}
	end)
	return Array.sortBy(players, function(player)
		return ROLE_ORDER[player.role]
	end)
end

function CustomMatchGroupInputBigMatch.getHeroPicks(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return Array.map(team.players or {}, Operator.property('champion'))
end

function CustomMatchGroupInputBigMatch.getHeroBans(map, opponentIndex)
	local bans = map.championVeto

	if not bans then return end

	bans = Array.sortBy(bans, Operator.property('vetoNumber'))
	bans = Array.filter(bans, function(veto)
		return veto.type == 'ban'
	end)
	bans = Array.filter(bans, function(veto)
		return veto.team == opponentIndex
	end)

	return Array.map(bans, Operator.property('champion'))
end

function CustomMatchGroupInputBigMatch.getVetoPhase(map)
	return map.championVeto
end

return CustomMatchGroupInputBigMatch
