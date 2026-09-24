---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local NormalMapParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')

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
---@field kast number?
---@field awpKills integer?
---@field tradeKills integer?
---@field tradeDeaths integer?

---@class MatchStatsPlayer
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
---@field rounds_won integer
---@field awp_kills integer
---@field trade_kill_count integer
---@field trade_death_count integer

---@class MatchStatsTeam
---@field team_name string
---@field players MatchStatsPlayer[]

---@class MatchStatsRound
---@field number integer
---@field team_a_name string
---@field team_b_name string
---@field team_a_side string
---@field team_b_side string
---@field winner_letter 'a'|'b'|''
---@field end_reason string? raw enum number from the demo parser, e.g. "7" for a defuse

---@class MatchStatsMap
---@field match {map_name: string?, duration: number?}
---@field teams MatchStatsTeam[]
---@field rounds MatchStatsRound[]

---@class CounterstrikeMatchPageMap: MatchStatsMap
---@field nuselo string|number?
---@field vod string?
---@field finished boolean?

---@class CounterstrikeMatchPageMapParser: MapParserInterface
local CustomMatchGroupInputMatchPage = {}

-- Each map's stats live on their own on-wiki page, named from the id in the
-- map's `nuselo=` parameter (api match checksum).
-- Placeholder while the module is developed; ideally proper API
local MATCH_STATS_PAGE_PREFIX = 'Data:Nuselo_'

-- Crosswalk of steamid -> Liquipedia player page name. Shared across matches.
local STEAMID_CROSSWALK_PAGE = 'Data:Cs2SteamIdCrosswalk.json'

local CS_MAP_NAMES = {
	de_dust2 = 'Dust II',
	de_mirage = 'Mirage',
	de_inferno = 'Inferno',
	de_nuke = 'Nuke',
	de_overpass = 'Overpass',
	de_vertigo = 'Vertigo',
	de_ancient = 'Ancient',
	de_anubis = 'Anubis',
	de_train = 'Train',
	de_cache = 'Cache',
}

local ROUND_SIDES = {['Terrorists'] = 't', ['Counter-Terrorists'] = 'ct'}

-- How a round was won, potentially export?
--
local ROUND_WIN_REASONS = {
	-- as current
	target_bombed = 'detonate',
	bomb_defused = 'defuse',
	ct_win = 'elimination',
	t_win = 'elimination',
	target_saved = 'time',
	draw = 'draw',
	['1'] = 'detonate',
	['7'] = 'defuse',
	['8'] = 'elimination',
	['9'] = 'elimination',
	['12'] = 'time',
	['16'] = 'draw',
}

---Whether this map actually has stats to read.
---Fallback
---@param map table
---@return boolean
local function hasStats(map)
	return map.nuselo ~= nil and map.teams ~= nil
end

---Normalises into Liquipedia win types.
---@param endReason string|number|nil
---@return string?
function CustomMatchGroupInputMatchPage.parseWinReason(endReason)
	if endReason == nil or endReason == '' then
		return nil
	end
	return ROUND_WIN_REASONS[tostring(endReason)]
end

---@param statsId string|number
---@return string
function CustomMatchGroupInputMatchPage.getStatsPageName(statsId)
	return MATCH_STATS_PAGE_PREFIX .. statsId .. '.json'
end

---Stats for one map, or nil when the page does not exist yet.
---
---Fallback for if a map hasnt been parsed yet, but equally a checksum
---would likely not exist yet anyway.
---Only applicable on a re process
---@param statsId string|number
---@return MatchStatsMap?
function CustomMatchGroupInputMatchPage.fetchMapStats(statsId)
	local pageName = CustomMatchGroupInputMatchPage.getStatsPageName(statsId)
	local success, mapStats = pcall(mw.loadJsonData, pageName)
	if not success or not mapStats then
		mw.log('No match stats at ' .. pageName .. ' - falling back to the manually entered map')
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

---Resolves a steamid to a Liquipedia player page via the crosswalk. Falls back
---to the stats provider's raw name (plain text, no link) if there is no match.
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

---If no `nuselo` id is present, this is a non data map and is passed through untouched
---`|reversed=` swaps which JSON team (teams[1]/teams[2]) is treated as opponent1/opponent2.
---@param mapInput table?
---@return table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	if not mapInput or not mapInput.nuselo then
		return mapInput
	end

	local mapStats = CustomMatchGroupInputMatchPage.fetchMapStats(mapInput.nuselo)
	if not mapStats then
		-- Re utilise map input when appropriate
		return mapInput
	end

	-- Merge onto mapInput to add other pass through like stats
	---@type CounterstrikeMatchPageMap
	local map = Table.merge(mapInput, mapStats)
	map.finished = true

	if Logic.readBool(mapInput.reversed) then
		map.teams = {map.teams[2], map.teams[1]}
	end

	return map
end

---@param map CounterstrikeMatchPageMap|table
---@return string?, string?
function CustomMatchGroupInputMatchPage.getMapName(map)
	local internalName = map.match and map.match.map_name
	if not internalName then
		-- Utilise original manual type for already provided data
		return map.map, map.map
	end
	local displayName = CS_MAP_NAMES[internalName] or internalName
	return displayName, displayName
end

---@param map CounterstrikeMatchPageMap|table
---@return string?
function CustomMatchGroupInputMatchPage.getLength(map)
	local seconds = map.match and map.match.duration
	if not seconds then
		return nil
	end
	return math.floor(seconds / 60) .. ':' .. string.format('%02d', seconds % 60)
end

---Team order in the provider JSON is assumed to match the match's opponent1/opponent2 order
--- This can be reversed
---@param map CounterstrikeMatchPageMap|table
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInputMatchPage.calculateMapScore(map)
	if not hasStats(map) then
		-- No id, or an id whose data has not landed yet
		-- default to prior
		return NormalMapParser.calculateMapScore(map)
	end
	return function(opponentIndex)
		local team = map.teams and map.teams[opponentIndex]
		local firstPlayer = team and team.players and team.players[1]
		return firstPlayer and firstPlayer.rounds_won or nil
	end
end

---@param map CounterstrikeMatchPageMap|table
---@param rounds MatchStatsRound[]
---@return boolean
local function isTeamAOpponent1(map, rounds)
	if map.teams and map.teams[1] and map.teams[1].team_name then
		return map.teams[1].team_name == rounds[1].team_a_name
	end
	return true
end

---round-number cutoffs.
---@param map CounterstrikeMatchPageMap|table
---@return table
local function deriveHalfScores(map)
	local rounds = map.rounds
	if not rounds or not rounds[1] then
		return {}
	end

	local teamAIsOpponent1 = isTeamAOpponent1(map, rounds)

	local t1sides, t2sides, t1halfs, t2halfs = {}, {}, {}, {}
	local blockT1Side, t1Wins, t2Wins = nil, 0, 0

	local function flushBlock()
		if not blockT1Side then
			return
		end
		table.insert(t1sides, blockT1Side)
		table.insert(t2sides, blockT1Side == 't' and 'ct' or 't')
		table.insert(t1halfs, t1Wins)
		table.insert(t2halfs, t2Wins)
	end

	for _, round in ipairs(rounds) do
		local aSide = ROUND_SIDES[round.team_a_side]
		local t1Side = teamAIsOpponent1 and aSide or ROUND_SIDES[round.team_b_side]

		if t1Side ~= blockT1Side then
			flushBlock()
			blockT1Side, t1Wins, t2Wins = t1Side, 0, 0
		end

		local t1Won = teamAIsOpponent1 == (round.winner_letter == 'a')
		if t1Won then
			t1Wins = t1Wins + 1
		else
			t2Wins = t2Wins + 1
		end
	end
	flushBlock()

	return {t1sides = t1sides, t2sides = t2sides, t1halfs = t1halfs, t2halfs = t2halfs}
end

---@class CounterstrikeRoundData
---@field round integer
---@field t1side 't'|'ct'
---@field t2side 't'|'ct'
---@field winningSide 't'|'ct'
---@field winBy string

---Round-by-round side/winner breakdown 
---@param map CounterstrikeMatchPageMap|table
---@return CounterstrikeRoundData[]?
local function getRounds(map)
	local rounds = map.rounds
	if not rounds or not rounds[1] then
		return nil
	end

	local teamAIsOpponent1 = isTeamAOpponent1(map, rounds)

	return Array.map(rounds, function(round)
		local t1Side = teamAIsOpponent1 and ROUND_SIDES[round.team_a_side] or ROUND_SIDES[round.team_b_side]
		local t2Side = t1Side == 't' and 'ct' or 't'
		local winningSide = (teamAIsOpponent1 == (round.winner_letter == 'a')) and t1Side or t2Side

		return {
			round = round.number,
			t1side = t1Side,
			t2side = t2Side,
			winningSide = winningSide,
			winBy = CustomMatchGroupInputMatchPage.parseWinReason(round.end_reason),
		}
	end)
end

---Maps without a `nuselo` id fall back to the manual parser
---@param match table
---@param map CounterstrikeMatchPageMap|table
---@param opponents MGIParsedOpponent[]
---@return table
function CustomMatchGroupInputMatchPage.getExtraData(match, map, opponents)
	if not hasStats(map) then
		return NormalMapParser.getExtraData(match, map, opponents)
	end
	local extradata = deriveHalfScores(map)
	extradata.nuselo = map.nuselo
	extradata.rounds = getRounds(map)
	return extradata
end

---@param player MatchStatsPlayer
---@return number?
local function headshotPercentage(player)
	if not player.kill_count or player.kill_count == 0 then
		return nil
	end
	return (player.headshot_count or 0) / player.kill_count * 100
end

---@param map CounterstrikeMatchPageMap|table
---@param opponent MGIParsedOpponent
---@param opponentIndex integer
---@return table[]
function CustomMatchGroupInputMatchPage.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local team = map.teams and map.teams[opponentIndex]
	local participantList = team and team.players or {}

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		participantList,
		function(playerIndex)
			local participant = participantList[playerIndex]
			if not participant then
				return nil
			end
			local resolved = CustomMatchGroupInputMatchPage.resolvePlayer(participant.steam_id, participant.name)
			if not resolved.player then
				-- No crosswalk match -- don't let parseMapPlayers guess-link the raw provider name.
				return nil
			end
			return {name = resolved.player}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local participant = participantList[playerIndex]
			local resolved = CustomMatchGroupInputMatchPage.resolvePlayer(participant.steam_id, participant.name)
			return {
				player = resolved.player,
				displayName = resolved.displayName,
				steamid = participant.steam_id and tostring(participant.steam_id) or nil,
				kills = participant.kill_count,
				deaths = participant.death_count,
				assists = participant.assist_count,
				adr = participant.average_damage_per_round,
				hs = headshotPercentage(participant),
				firstKills = participant.first_kill_count,
				firstDeaths = participant.first_death_count,
				kast = participant.kast,
				awpKills = participant.awp_kills,
				tradeKills = participant.trade_kill_count,
				tradeDeaths = participant.trade_death_count,
			}
		end
	)
end

---@param games table[]
---@return table[]
function CustomMatchGroupInputMatchPage.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end

return CustomMatchGroupInputMatchPage
