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

---@class dota2MatchDataExtended: dota2MatchData
---@field matchid integer

---@param mapInput {matchid: string?, reversed: string?}
---@return dota2MatchDataExtended|table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end
	local matchId = tonumber(mapInput.matchid)
	assert(matchId, 'Numeric matchid expected, got ' .. mapInput.matchid)

	local map = mw.ext.Dota2DB.getBigMatch(matchId, Logic.readBool(mapInput.reversed))

	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')
	---@cast map dota2MatchDataExtended
	map.matchid = matchId

	return map
end

---@param map dota2MatchDataExtended
---@return string|nil
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

---@param map dota2MatchDataExtended
---@param opponentIndex integer
---@return string|nil
function CustomMatchGroupInputMatchPage.getSide(map, opponentIndex)
	local team = map['team' .. opponentIndex] ---@type dota2MatchTeam?
	return (team or {}).side
end

---@param map dota2MatchDataExtended
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local team = map['team' .. opponentIndex] ---@type dota2MatchTeam?
	if not team then return end
	if not team.players then return end

	local function mapItem(item)
		return {
			name = item.name,
			image = item.image,
		}
	end
	local function fetchLpdbPlayer(playerId)
		if not playerId then return end
		return mw.ext.LiquipediaDB.lpdb('player', {
			conditions = '[[extradata_playerid::' .. playerId .. ']]',
			query = 'pagename, id',
		})[1]
	end
	local players = Array.map(team.players, function(player)
		local playerData = fetchLpdbPlayer(player.id) or {}
		return {
			player = playerData.pagename or player.name,
			name = playerData.id,
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

---@param map dota2MatchDataExtended
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputMatchPage.getHeroPicks(map, opponentIndex)
	local team = map['team' .. opponentIndex] ---@type dota2MatchTeam?
	if not team then return end
	return Array.map(team.players or {}, Operator.property('heroName'))
end

---@param map dota2MatchDataExtended
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputMatchPage.getHeroBans(map, opponentIndex)
	if not map.heroVeto then return end
	local teamVeto = map.heroVeto['team' .. opponentIndex] ---@type dota2TeamVeto?
	if not teamVeto then return end
	return Array.map(teamVeto.bans or {}, Operator.property('hero'))
end

---@param map dota2MatchDataExtended
---@return {character: string?, team: integer, type: 'pick'|'ban', vetoNumber: integer}[]|nil
function CustomMatchGroupInputMatchPage.getVetoPhase(map)
	if not map.heroVeto then return end

	local buildVetoData = function(teamIdx, vetoType)
		local teamVeto = map.heroVeto['team' .. teamIdx] ---@type dota2TeamVeto?
		if not teamVeto then return {} end
		local vetoesOfType = teamVeto[vetoType .. 's'] ---@type dota2VetoEntry[]
		return Array.map(vetoesOfType or {}, function(vetoData)
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

---@param map dota2MatchDataExtended
---@param opponentIndex integer
---@return {towers: integer?, barracks: integer?, roshans: integer?}?
function CustomMatchGroupInputMatchPage.getObjectives(map, opponentIndex)
	local team = map['team' .. opponentIndex] ---@type dota2MatchTeam?
	if not team then return end
	return {
		towers = team.towersDestroyed,
		barracks = team.barracksDestroyed,
		roshans = team.roshanKills,
	}
end

return CustomMatchGroupInputMatchPage
