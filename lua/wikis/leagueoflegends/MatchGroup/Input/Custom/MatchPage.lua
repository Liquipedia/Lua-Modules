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

---@class LeagueOfLegendsMatchPageMapParser: LeagueOfLegendsMapParserInterface
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

---@param mapInput table
---@return table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.LeagueOfLegendsDB.getData(mapInput.matchid, Logic.readBool(mapInput.reversed))
	-- Match not found on the API
	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')

	local function sortPlayersOnRole(team)
		if not team.players then return end
		team.players = Array.sortBy(team.players, function(player)
			return ROLE_ORDER[player.role]
		end)
	end
	sortPlayersOnRole(map.team1)
	sortPlayersOnRole(map.team2)

	-- Manually import vod from input
	map.vod = mapInput.vod
	return map
end

---@param map table
---@return string?
function CustomMatchGroupInputMatchPage.getLength(map)
	if not map.length or not Logic.isNumeric(map.length) then
		return
	end
	-- Convert seconds to minutes and seconds
	return math.floor(map.length / 60) .. ':' .. string.format('%02d', map.length % 60)
end

---@param map table
---@param opponentIndex integer
---@return string?
function CustomMatchGroupInputMatchPage.getSide(map, opponentIndex)
	return (map['team' .. opponentIndex] or {}).color
end

---@param map table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	if not team.players then return end
	return Array.map(team.players, function(player)
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
end

---@param map table
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputMatchPage.getHeroPicks(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return Array.map(team.players or {}, Operator.property('champion'))
end

---@param map table
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputMatchPage.getHeroBans(map, opponentIndex)
	if not map.championVeto then return end

	local bans = Array.filter(map.championVeto, function(veto)
		return veto.type == 'ban' and veto.team == opponentIndex
	end)

	return Array.map(bans, Operator.property('champion'))
end

---@param map table
---@return table[]?
function CustomMatchGroupInputMatchPage.getVetoPhase(map)
	if not map.championVeto then return end
	return Array.map(map.championVeto, function(veto)
		veto.character = veto.champion
		veto.champion = nil
		return veto
	end)
end

---@param map table
---@param opponentIndex integer
---@return table<string, integer>?
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
