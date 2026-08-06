---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

---@class CounterstrikeMatchPagePlayerStats
---@field player string?
---@field displayName string
---@field steamid string?
---@field kills integer?
---@field deaths integer?
---@field assists integer?
---@field adr number?
---@field hs number?
---@field firstKills integer?
---@field firstDeaths integer?

---@class NuseloPlayerStats
---@field steam_id integer
---@field name string
---@field team_name string
---@field kill_count integer
---@field assist_count integer
---@field death_count integer
---@field headshot_count integer
---@field kast number
---@field average_damage_per_round number
---@field first_kill_count integer
---@field first_death_count integer

---@class NuseloTeam
---@field team_name string
---@field players NuseloPlayerStats[]

---@class NuseloMapStats
---@field match table
---@field teams NuseloTeam[]
---@field rounds table[]

local CustomMatchGroupInputMatchPage = {}

-- Each map's player stats live on their own wiki page CURRENTLY, named from the map's
-- `nuselo` id (`|nuselo=` within a {{Map|...}} item.
-- This is a TEMP placeholder while the module is built (hopefully). The plan is
-- to key these by the match id (lp matchId and map) once the full module is built out, and
-- eventually move storage to LPDB extradata instead of dedicated wiki pages.
local NUSELO_PAGE_PREFIX = 'Data:Nuselo_'

-- Crosswalk of steamid -> Liquipedia player page name. Shared across matches.
local STEAMID_CROSSWALK_PAGE = 'Data:Cs2SteamIdCrosswalk.json'

---@param nuseloId string|number
---@return string
function CustomMatchGroupInputMatchPage.getStatsPageName(nuseloId)
	return NUSELO_PAGE_PREFIX .. nuseloId .. '.json'
end

---@param nuseloId string|number?
---@return NuseloMapStats?
function CustomMatchGroupInputMatchPage.getMapStats(nuseloId)
	if Logic.isEmpty(nuseloId) then
		return nil
	end
	---@cast nuseloId -nil

	-- The page may not exist yet (stats not uploaded for this map) expected, fail soft
	local success, mapStats = pcall(mw.loadJsonData, CustomMatchGroupInputMatchPage.getStatsPageName(nuseloId))
	if not success then
		return nil
	end
	return mapStats
end

---@return table<string, string>
function CustomMatchGroupInputMatchPage.getSteamIdCrosswalk()
	local success, crosswalk = pcall(mw.loadJsonData, STEAMID_CROSSWALK_PAGE)
	if not success then
		return {}
	end
	return crosswalk or {}
end

---Resolves a steamid to a Liquipedia player page via the crosswalk json. Falls back if no match
---@param steamId integer|string?
---@param fallbackName string?
---@return {player: string?, displayName: string}
function CustomMatchGroupInputMatchPage.resolvePlayer(steamId, fallbackName)
	local steamIdKey = steamId and tostring(steamId) or nil
	local pageName = steamIdKey and CustomMatchGroupInputMatchPage.getSteamIdCrosswalk()[steamIdKey] or nil

	return {
		player = pageName,
		displayName = pageName or fallbackName or steamIdKey or 'Unknown',
	}
end

---@param player NuseloPlayerStats
---@return number?
local function headshotPercentage(player)
	if not player.kill_count or player.kill_count == 0 then
		return nil
	end
	return (player.headshot_count or 0) / player.kill_count * 100
end

---Team order in the JSON is assumed to match API response, need to add a switch var?
---@param nuseloId string|number?
---@param teamIndex integer
---@return CounterstrikeMatchPagePlayerStats[]
function CustomMatchGroupInputMatchPage.getPlayers(nuseloId, teamIndex)
	local mapStats = CustomMatchGroupInputMatchPage.getMapStats(nuseloId)
	local team = mapStats and mapStats.teams and mapStats.teams[teamIndex]
	if not team then
		return {}
	end

	return Array.map(team.players or {}, function(player)
		local resolved = CustomMatchGroupInputMatchPage.resolvePlayer(player.steam_id, player.name)
		return {
			player = resolved.player,
			displayName = resolved.displayName,
			steamid = player.steam_id and tostring(player.steam_id) or nil,
			kills = player.kill_count,
			deaths = player.death_count,
			assists = player.assist_count,
			adr = player.average_damage_per_round,
			hs = headshotPercentage(player),
			firstKills = player.first_kill_count,
			firstDeaths = player.first_death_count,
		}
	end)
end

return CustomMatchGroupInputMatchPage
