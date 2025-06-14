---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')

local MapData = mw.loadJsonData('MediaWiki:Valorantdb-maps.json')

local CustomMatchGroupInputMatchPage = {}

---@class valorantMatchApiTeamExtended: valorantMatchApiTeam
---@field players valorantMatchApiPlayer[]

---@class valorantMatchDataExtended: valorantMatchData
---@field teams valorantMatchApiTeamExtended[]
---@field matchid string
---@field vod string?
---@field finished boolean

local ROUNDS_PER_HALF = 12
local ROUNDS_IN_GAME = 24

---@param side 'atk'|'def'
---@return 'atk'|'def'
local function otherSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

---@param longName 'Attacker'|'Defender'
---@return 'atk'|'def'
local function makeShortSideName(longName)
	if longName == 'Attacker' then
		return 'atk'
	end
	return 'def'
end

---@param mapInput {matchid: string?, reversed: string?, vod: string?, region: string?}
---@return valorantMatchDataExtended|table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end

	local map = mw.ext.valorantdb.getMatchDetails(mapInput.matchid)

	assert(map, mapInput.matchid .. ' could not be retrieved from API.')

	local shouldReverse = Logic.readBool(mapInput.reversed)

	if shouldReverse then
		map.teams[1], map.teams[2] = map.teams[2], map.teams[1]
	end

	---@cast map valorantMatchDataExtended
	-- Attach players to their teams
	Array.forEach(map.teams, function(team)
		team.players = Array.filter(map.players, function(player)
			return player.team_id == team.team_id
		end)
	end)
	map.region = mapInput.region -- Region from the API is not what we want for region
	map.matchid = mapInput.matchid
	map.vod = mapInput.vod
	map.finished = true

	return map
end

---@param map valorantMatchDataExtended|table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	if not map.teams then return nil end
	local team = map.teams[opponentIndex]
	if not team then return end

	return Array.map(team.players, function(player)
		local lpdbPlayerData = player.lpdb_player
		return {
			player = lpdbPlayerData and lpdbPlayerData.page_name or player.game_name,
			agent = player.character.name,
			acs = player.stats.acs,
			adr = player.stats.adr,
			kast = player.stats.kast,
			hs = player.stats.head_shot_percent,
			kills = player.stats.kills,
			deaths = player.stats.deaths,
			assists = player.stats.assists,
		}
	end)
end

---@param map valorantMatchDataExtended|table
---@param opponentIndex integer
---@param phase 'normal'|'ot'
---@return 'atk'|'def'|nil
function CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex, phase)
	if not map.round_results then return nil end

	local teamSide = map.teams[opponentIndex] and map.teams[opponentIndex].team_id

	local roundNumberOfFirstRound = phase == 'normal' and 1 or (ROUNDS_IN_GAME + 1)
	local firstRound = Array.find(map.round_results, function(round)
		return round.round_num == roundNumberOfFirstRound
	end)

	if not firstRound then return nil end

	if firstRound.winning_team == teamSide then
		return makeShortSideName(firstRound.winning_team_role)
	else
		return otherSide(makeShortSideName(firstRound.winning_team_role))
	end
end

---@param map valorantMatchDataExtended|table
---@param side 'atk'|'def'|'otatk'|'otdef'
---@param opponentIndex integer
---@return integer?
function CustomMatchGroupInputMatchPage.getScoreFromRounds(map, side, opponentIndex)
	if not map.teams then return nil end
	local team = map.teams[opponentIndex]
	local firstSide = CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex, 'normal')
	local firstSideOt = CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex, 'ot')
	local condition
	if firstSide then
		if side == firstSide then
			condition = function(round) return round.round_num <= ROUNDS_PER_HALF end
		elseif side == otherSide(firstSide) then
			condition = function(round) return round.round_num > ROUNDS_PER_HALF and round.round_num <= ROUNDS_IN_GAME end
		end
	end
	if firstSideOt then
		if side == 'ot' .. firstSideOt then
			condition = function(round) return round.round_num > ROUNDS_IN_GAME and round.round_num % 2 == 1 end
		elseif side == 'ot' .. otherSide(firstSideOt) then
			condition = function(round) return round.round_num > ROUNDS_IN_GAME and round.round_num % 2 == 0 end
		end
	end
	if not condition then
		return nil
	end

	local roundsWon = Array.filter(Array.filter(map.round_results, condition), function(round)
		return round.winning_team == team.team_id
	end)
	return #roundsWon
end

---@param map valorantMatchDataExtended|table
---@return string?
function CustomMatchGroupInputMatchPage.getMapName(map)
	return MapData[map.map_id] or map.map
end

---@param map valorantMatchDataExtended|table
---@return string?, string?
function CustomMatchGroupInputMatchPage.getMatchId(map)
	return map.matchid, map.region
end

---@param map valorantMatchDataExtended|table
---@return string?
function CustomMatchGroupInputMatchPage.getLength(map)
	if not map.game_length_millis then return nil end
	local seconds = map.game_length_millis / 1000
	return math.floor(seconds / 60) .. ':' .. string.format('%02d', seconds % 60)
end

---@param map valorantMatchDataExtended|table
---@return ValorantRoundData[]?
function CustomMatchGroupInputMatchPage.getRounds(map)
	if not map.round_results then return nil end

	local function mapResultCodes(resultCode)
		if resultCode == 'Defuse' then
			return 'defuse'
		elseif resultCode == 'Elimination' then
			return 'elimination'
		elseif resultCode == 'Detonate' then
			return 'detonate'
		elseif resultCode == 'Surrendered' then
			return 'surrendered'
		elseif resultCode == '' then
			return 'time'
		else
			return 'unknown'
		end
	end

	local t1start = CustomMatchGroupInputMatchPage.getFirstSide(map, 1, 'normal')
	local t1startot = CustomMatchGroupInputMatchPage.getFirstSide(map, 1, 'ot')
	local nextOvertimeSide = t1startot

	if not t1start then
		return nil
	end
	return Array.map(map.round_results, function(round)
		local roundNumber = round.round_num
		local t1side, t2side
		if roundNumber <= ROUNDS_PER_HALF then
			t1side = t1start
			t2side = otherSide(t1start)
		elseif roundNumber <= ROUNDS_IN_GAME then
			t1side = otherSide(t1start)
			t2side = t1start
		elseif nextOvertimeSide then
			-- In overtime they switch sides every round
			t1side = nextOvertimeSide
			t2side = otherSide(nextOvertimeSide)
			nextOvertimeSide = otherSide(nextOvertimeSide)
		end

		if not t1side or not t2side then
			return nil
		end

		---@type ValorantRoundData
		return {
			round = roundNumber,
			t1side = t1side,
			t2side = t2side,
			winningSide = makeShortSideName(round.winning_team_role),
			winBy = mapResultCodes(round.round_result_code),
		}
	end)
end

---@param map valorantMatchDataExtended|table
---@return string?
function CustomMatchGroupInputMatchPage.getPatch(map)
	--- input format is "release-10.05-shipping-14-3367018"
	local versionParts = Array.parseCommaSeparatedString(map.game_version, '-')
	return versionParts[2]
end

return CustomMatchGroupInputMatchPage
