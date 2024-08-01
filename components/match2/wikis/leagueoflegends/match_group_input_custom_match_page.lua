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

local CustomMatchGroupInputMatchPage = {}

local ROLE_ORDER = Table.map({
	'top',
	'jungle',
	'middle',
	'bottom',
	'support',
}, function(idx, value)
	return value, idx
end)

function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.LeagueOfLegendsDB.getData(mapInput.matchid, Logic.readBool(mapInput.reversed))
	-- Match not found on the API
	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')

	return map
end

function CustomMatchGroupInputMatchPage.getLength(map)
	if not map.length or not Logic.isNumeric(map.length) then
		return
	end
	-- Convert seconds to minutes and seconds
	return math.floor(map.length / 60) .. ':' .. string.format('%02d', map.length % 60)
end

function CustomMatchGroupInputMatchPage.getSide(map, opponentIndex)
	return (map['team' .. opponentIndex] or {}).color
end

function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	if not team.players then return end
	local players = Array.map(team.players, function(player)
		return {
			player = player.id,
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
			spells = player.spells,
		}
	end)
	return Array.sortBy(players, function(player)
		return ROLE_ORDER[player.role]
	end)
end

---@param map {championVeto: table[]?}
---@param vetoType 'pick'|'ban'
---@param opponentIndex 1|2
---@return table[]?
local function getVetoesOfPick(map, vetoType, opponentIndex)
	if not map.championVeto then return end
	return Array.filter(map.championVeto, function(veto)
		return veto.type == vetoType and veto.team == opponentIndex
	end)
end

function CustomMatchGroupInputMatchPage.getHeroPicks(map, opponentIndex)
	local bans = getVetoesOfPick(map, 'pick', opponentIndex)

	if not bans then return end

	return Array.map(bans, Operator.property('champion'))
end

function CustomMatchGroupInputMatchPage.getHeroBans(map, opponentIndex)
	local bans = getVetoesOfPick(map, 'ban', opponentIndex)

	if not bans then return end

	return Array.map(bans, Operator.property('champion'))
end

function CustomMatchGroupInputMatchPage.getVetoPhase(map)
	if not map.championVeto then return end
	return Array.map(map.championVeto, function(veto)
		veto.character = veto.champion
		veto.champion = nil
		return veto
	end)
end

function CustomMatchGroupInputMatchPage.getObjectives(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return {
		towers = team.towerKills,
		inhibitors = team.inhibitorKills,
		barons = team.baronKills,
		dragons = team.dragonKills,
		heralds = team.heraldKills,
	}
end

return CustomMatchGroupInputMatchPage
