---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Operator = require('Module:Operator')

local CustomMatchGroupInputMatchPage = {}

function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.Dota2DB.getBigMatch(mapInput.matchid, Logic.readBool(mapInput.reversed))

	-- Match not found on the API
	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')
	map.matchid = mapInput.matchid

	return map
end

function CustomMatchGroupInputMatchPage.getLength(map)
	if Logic.isEmpty(map.length) and Logic.isEmpty(map.lengthInSeconds) then
		return
	end
	if Logic.isNumeric(map.lengthInSeconds) then
		-- Convert seconds to minutes and seconds
		return math.floor(map.lengthInSeconds / 60) .. ':' .. string.format('%02d', map.lengthInSeconds % 60)
	end
	return map.length
end

function CustomMatchGroupInputMatchPage.getSide(map, opponentIndex)
	return (map['team' .. opponentIndex] or {}).side
end

function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	if not team.players then return end
	local players = Array.map(team.players, function(player)
		return {
			player = player.name,
			role = player.position,
			facet = player.facet,
			character = player.heroName,
			level = player.level,
			xpm = player.xpPerMinute,
			gold = player.totalGold,
			gpm = player.goldPerMinute,
			kills = player.kills,
			deaths = player.deaths,
			assists = player.assists,
			damagedone = player.damage,
			lasthits = player.lastHits,
			denies = player.denies,
			items = player.items,
			backpackitems = player.backpackItems,
			neutralitem = player.neutralItem,
			scepter = Logic.readBool(player.scepter),
			shard = Logic.readBool(player.shard),
		}
	end)
	return Array.sortBy(players, function(player)
		return player.role or player.player
	end)
end

function CustomMatchGroupInputMatchPage.getHeroPicks(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return Array.map(team.players or {}, Operator.property('heroName'))
end

function CustomMatchGroupInputMatchPage.getHeroBans(map, opponentIndex)
	local bans = map.heroVeto

	if not bans then return end

	bans = Array.sortBy(bans, Operator.property('vetoNumber'))
	bans = Array.filter(bans, function(veto)
		return veto.type == 'ban'
	end)
	bans = Array.filter(bans, function(veto)
		return veto.team == opponentIndex
	end)

	return Array.map(bans, Operator.property('hero'))
end

function CustomMatchGroupInputMatchPage.getVetoPhase(map)
	if not map.heroVeto then return end
	return Array.map(map.heroVeto, function(veto)
		veto.character = veto.heroName
		veto.heroName = nil
		return veto
	end)
end

function CustomMatchGroupInputMatchPage.getObjectives(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return {
		towers = team.towersDestroyed,
		barracks = team.barracksDestroyed,
		roshans = team.roshanKills,
	}
end

return CustomMatchGroupInputMatchPage
