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

	local map = mw.ext.Dota2DB.getBigMatch(tonumber(mapInput.matchid), Logic.readBool(mapInput.reversed))

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

	local function mapItem(item)
		return {
			name = item.name,
			image = item.image,
		}
	end
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
			items = Array.map(player.items or {}, mapItem),
			backpackitems = Array.map(player.backpackItems or {} , mapItem),
			neutralitem = mapItem(player.neutralItem or {}),
			scepter = Logic.readBool(player.aghanimsScepterBuff),
			shard = Logic.readBool(player.aghanimsShardBuff),
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
	local teamVeto = map.heroVeto['team' .. opponentIndex]
	if not teamVeto then return end
	return Array.map(teamVeto.bans or {}, Operator.property('hero'))
end

function CustomMatchGroupInputMatchPage.getVetoPhase(map)
	if not map.heroVeto then return end
	local buildVetoData = function(teamIdx, vetoType)
		if not map.heroVeto['team' .. teamIdx] then return {} end
		return Array.map(map.heroVeto['team' .. teamIdx][vetoType .. 's'] or {}, function(vetoData)
			return {
				character = vetoData.hero,
				team = teamIdx,
				type = vetoType,
				vetoNumber = vetoData.order,
			}
		end)
	end
	local vetoPhase = Array.extend(
		buildVetoData(1, 'ban'),
		buildVetoData(2, 'ban'),
		buildVetoData(1, 'pick'),
		buildVetoData(2, 'pick')
	)
	return Array.sortBy(vetoPhase, function(veto)
		return veto.vetoNumber
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
