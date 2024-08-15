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

	--local map = mw.ext.LeagueOfLegendsDB.getData(mapInput.matchid, Logic.readBool(mapInput.reversed))
	local map = {
		heroVeto = {
			{
				hero = "Axe",
				team = 1,
				type = "ban",
				vetoNumber = 1,
			},
			{
				hero = "Axe",
				team = 2,
				type = "ban",
				vetoNumber = 2,
			},
			{
				hero = "Axe",
				team = 1,
				type = "ban",
				vetoNumber = 3,
			},
			{
				hero = "Axe",
				team = 2,
				type = "ban",
				vetoNumber = 4,
			},
			{
				hero = "Axe",
				team = 1,
				type = "ban",
				vetoNumber = 5,
			},
			{
				hero = "Axe",
				team = 2,
				type = "ban",
				vetoNumber = 6,
			},
			{
				hero = "Axe",
				team = 1,
				type = "pick",
				vetoNumber = 7,
			},
			{
				hero = "Axe",
				team = 2,
				type = "pick",
				vetoNumber = 8,
			},
			{
				hero = "Axe",
				team = 2,
				type = "pick",
				vetoNumber = 9,
			},
			{
				hero = "Axe",
				team = 1,
				type = "pick",
				vetoNumber = 10,
			},
			{
				hero = "Axe",
				team = 1,
				type = "pick",
				vetoNumber = 11,
			},
			{
				hero = "Axe",
				team = 2,
				type = "pick",
				vetoNumber = 12,
			},
			{
				hero = "Axe",
				team = 2,
				type = "ban",
				vetoNumber = 13,
			},
			{
				hero = "Axe",
				team = 1,
				type = "ban",
				vetoNumber = 14,
			},
			{
				hero = "Axe",
				team = 2,
				type = "ban",
				vetoNumber = 15,
			},
			{
				hero = "Axe",
				team = 1,
				type = "ban",
				vetoNumber = 16,
			},
			{
				hero = "Axe",
				team = 2,
				type = "pick",
				vetoNumber = 17,
			},
			{
				hero = "Axe",
				team = 1,
				type = "pick",
				vetoNumber = 18,
			},
			{
				hero = "Axe",
				team = 1,
				type = "pick",
				vetoNumber = 19,
			},
			{
				hero = "Axe",
				team = 2,
				type = "pick",
				vetoNumber = 20,
			},
		},
		length = 3259,
		team1 = {
			roshanKills = 4,
			side = "dire",
			barrackKills = 8,
			name = "DK Challengers",
			players = {
				{
					assists = 11,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 10845,
					deaths = 3,
					gold = 13638,
					gpm = 250,
					facet = "wow",
					id = "Moham",
					items = {
						"Celestial Opposition",
						"Locket of the Iron Solari",
						"Mercury's Treads",
						"Abyssal Mask",
						"Warmog's Armor",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 0,
					position = 1,
					scepter = true,
					shard = true,
				},
				{
					assists = 3,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 36175,
					deaths = 1,
					gold = 27202,
					gpm = 250,
					facet = "wow",
					id = "Siwoo",
					items = {
						"Black Cleaver",
						"Sterak's Gage",
						"Guardian Angel",
						"Spear of Shojin",
						"Mercury's Treads",
						"Spirit Visage",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 8,
					position = 2,
					scepter = true,
					shard = true,
				},
				{
					assists = 11,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 53326,
					deaths = 5,
					gold = 19044,
					gpm = 250,
					facet = "wow",
					id = "Sharvel",
					items = {
						"Mercury's Treads",
						"Liandry's Torment",
						"Morellonomicon",
						"Horizon Focus",
						"Cryptbloom",
						"Banshee's Veil",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 1,
					position = 3,
					scepter = true,
					shard = true,
				},
				{
					assists = 5,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 46750,
					deaths = 2,
					gold = 24085,
					gpm = 250,
					facet = "wow",
					id = "Wayne",
					items = {
						"Lord Dominik's Regards",
						"Rapid Firecannon",
						"Infinity Edge",
						"Mercury's Treads",
						"Statikk Shiv",
						"Bloodthirster",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 3,
					position = 4,
					scepter = true,
					shard = true,
				},
				{
					assists = 2,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 54354,
					deaths = 7,
					gold = 26944,
					gpm = 250,
					facet = "wow",
					id = "Saint",
					items = {
						"Bloodthirster",
						"Lord Dominik's Regards",
						"Rapid Firecannon",
						"Essence Reaver",
						"Kraken Slayer",
						"Infinity Edge",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 6,
					position = 5,
					scepter = true,
					shard = true,
				},
			},
			towerKills = 11,
		},
		team2 = {
			roshanKills = 0,
			side = "radiant",
			barrackKills = 1,
			name = "Gen.G Global Academy",
			players = {
				{
					assists = 11,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 37959,
					deaths = 5,
					gold = 18973,
					gpm = 250,
					facet = "wow",
					id = "Toye",
					items = {
						"Zhonya's Hourglass",
						"Blighting Jewel",
						"Rylai's Crystal Scepter",
						"Morellonomicon",
						"Sorcerer's Shoes",
						"Liandry's Torment",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 2,
					position = 1,
					scepter = true,
					shard = true,
				},
				{
					assists = 8,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 54632,
					deaths = 2,
					gold = 21090,
					gpm = 250,
					facet = "wow",
					id = "Enoe",
					items = {
						"Rabadon's Deathcap",
						"Void Staff",
						"Liandry's Torment",
						"Morellonomicon",
						"Archangel's Staff",
						"Sorcerer's Shoes",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 4,
					position = 2,
					scepter = true,
					shard = true,
				},
				{
					assists = 7,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 7756,
					deaths = 8,
					gold = 12510,
					gpm = 250,
					facet = "wow",
					id = "Bairn",
					items = {
						"Locket of the Iron Solari",
						"Knight's Vow",
						"Mercury's Treads",
						"Shurelya's Battlesong",
						"Gargoyle Stoneplate",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 1,
					position = 3,
					scepter = true,
					shard = true,
				},
				{
					assists = 2,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 37518,
					deaths = 7,
					gold = 21834,
					gpm = 250,
					facet = "wow",
					id = "Wyz",
					items = {
						"Frozen Heart",
						"Mercury's Treads",
						"Gargoyle Stoneplate",
						"Sunfire Aegis",
						"Thornmail",
						"Sterak's Gage",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 4,
					position = 4,
					scepter = true,
					shard = true,
				},
				{
					assists = 3,
					hero = "Axe",
					lastHits = 58,
					denies = 5,
					damageDone = 56480,
					deaths = 3,
					gold = 26010,
					gpm = 250,
					facet = "wow",
					id = "Drake",
					items = {
						"Kraken Slayer",
						"Manamune",
						"Muramana",
						"Phantom Dancer",
						"Infinity Edge",
						"Rapid Firecannon",
					},
					backpackItems = {
						"Apex",
						"Apex",
						"Apex",
					},
					neutralItem = "Apex",
					kills = 5,
					position = 5,
					scepter = true,
					shard = true,
				},
			},
			towerKills = 6,
		},
		timestamp = 1549514861,
		winner = 1,
	}

	-- Match not found on the API
	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')
	map.matchid = mapInput.matchid

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
	return (map['team' .. opponentIndex] or {}).side
end

function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	if not team.players then return end
	local players = Array.map(team.players, function(player)
		return {
			player = player.id,
			role = player.position,
			facet = player.facet,
			character = player.hero,
			gold = player.gold,
			gpm = player.gpm,
			kills = player.kills,
			deaths = player.deaths,
			assists = player.assists,
			damagedone = player.damageDone,
			lasthits = player.lastHits,
			denies = player.denies,
			items = player.items,
			backpackitems = player.backpackItems,
			neutralitem = player.neutralItem,
			scepter = player.scepter,
			shard = player.shard,
		}
	end)
	return Array.sortBy(players, function(player)
		return player.role or player.player
	end)
end

function CustomMatchGroupInputMatchPage.getHeroPicks(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return Array.map(team.players or {}, Operator.property('hero'))
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
		veto.character = veto.hero
		veto.hero = nil
		return veto
	end)
end

function CustomMatchGroupInputMatchPage.getObjectives(map, opponentIndex)
	local team = map['team' .. opponentIndex]
	if not team then return end
	return {
		towers = team.towerKills,
		barracks = team.barrackKills,
		roshans = team.roshanKills,
	}
end

return CustomMatchGroupInputMatchPage
