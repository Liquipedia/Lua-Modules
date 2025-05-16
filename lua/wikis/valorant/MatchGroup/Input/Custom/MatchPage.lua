---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')

local CustomMatchGroupInputMatchPage = {}

---@class valorantMatchDataExtended: valorantMatchData
---@field matchid string
---@field vod string?
---@field finished boolean

local function otherSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

---@param mapInput {matchid: string?, reversed: string?, vod: string?, region: string?}
---@return dota2MatchDataExtended|table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end
	assert(mapInput.region, 'Region is required')

	local map = mw.ext.valorantdb.getDetails(mapInput.matchid, mapInput.region, Logic.readBool(mapInput.reversed))

	assert(map and type(map) == 'table' and map.matchInfo, mapInput.matchid .. ' could not be retrieved.')

	-- Let's shift the array to start from 1
	-- This is a temporary workaround for the API returning 0-indexed arrays
	if map.players and type(map.players) == 'table' and map.players[0] then
		local newTeams = {}
		for i, team in pairs(map.players) do
			local newPlayers = {}
			for j, player in pairs(team) do
				newPlayers[j + 1] = player
			end

			newTeams[i + 1] = team
			newTeams[i + 1].players = newPlayers
		end
		map.players = newTeams
	end
	if map.roundDetails and type(map.roundDetails) == 'table' and map.roundDetails[0] then
		local newRoundDetails = {}
		for i, roundDetail in pairs(map.roundDetails) do
			newRoundDetails[i + 1] = roundDetail
		end
		map.roundDetails = newRoundDetails
	end
	if map.teams and type(map.teams) == 'table' and map.teams[0] then
		local newTeams = {}
		for i, team in pairs(map.teams) do
			newTeams[i + 1] = team
		end
		map.teams = newTeams
	end

	-- Fix round winner
	-- We are currently getting the side the team started the NEXT round on, but it should be THIS round.
	-- This is a temporary fix until the API is fixed
	if map.roundDetails and type(map.roundDetails) == 'table' then
		Array.forEach(map.roundDetails, function(roundDetail)
			if roundDetail.round_no % 12 == 0 or roundDetail.round_no > 24 then
				-- In overtime, the winner is the opposite of the round number
				-- Same with the last round of each side in normal time (12, 24)
				roundDetail.round_winner = otherSide(roundDetail.round_winner)
			else
				roundDetail.round_winner = roundDetail.round_winner
			end
		end)
	end

	-- Temporary reverse logic until the API has this feature added
	if Logic.readBool(mapInput.reversed) then
		map.matchInfo.team1, map.matchInfo.team2 = map.matchInfo.team2, map.matchInfo.team1
		map.matchInfo.t1firstside = otherSide(map.matchInfo.t1firstside)
		map.matchInfo.o1t1firstside = otherSide(map.matchInfo.o1t1firstside)
		Array.forEach(map.roundDetails, function(roundDetail)
			roundDetail.winningSide = otherSide(roundDetail.winningSide)
		end)
		map.teams[1], map.teams[2] = map.teams[2], map.teams[1]
		map.players[1], map.players[2] = map.players[2], map.players[1]
	end

	---@cast map valorantMatchDataExtended
	map.matchid = mapInput.matchid
	map.vod = mapInput.vod
	map.finished = true

	return map
end

---@param map table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	if not map.players then return nil end
	local teamPlayers = map.players[opponentIndex]
	if not teamPlayers then return end

	local players = Array.map(teamPlayers.players, function(player)
		return {
			player = player.riot_id,
			agent = player.agent,
			acs = player.acs,
			adr = nil,
			kast = nil,
			hs = nil,
			kills = player.kills,
			deaths = player.deaths,
			assists = player.assists,
		}
	end)
	return Array.reverse(Array.sortBy(players, function(player)
		return player.acs or player.kills or player.player
	end))
end

---@param map table
---@param opponentIndex integer
---@param phase 'normal'|'ot'
---@return 'atk'|'def'|nil
function CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex, phase)
	if not map.matchInfo then return nil end
	if phase == 'normal' then
		return map.matchInfo['t' .. opponentIndex .. 'firstside']
	else
		return map.matchInfo['o1t' .. opponentIndex .. 'firstside']
	end
end

---@param map table
---@param side 'atk'|'def'|'otatk'|'otdef'
---@param opponentIndex integer
---@return integer?
function CustomMatchGroupInputMatchPage.getScoreFromRounds(map, side, opponentIndex)
	if not map.matchInfo then return nil end
	local teamColor = map.matchInfo['team' .. opponentIndex]
	if not teamColor then
		return nil
	end
	local sideData = map.matchInfo[teamColor]
	if not sideData then
		return nil
	end
	return sideData['team' .. side .. 'wins']
end

---@param map table
---@return string?
function CustomMatchGroupInputMatchPage.getMapName(map)
	if not map.matchInfo then
		return map.map
	end
	return map.matchInfo.mapId
end

---@param map table
---@return string?, string?
function CustomMatchGroupInputMatchPage.getMatchId(map)
	return map.matchid, map.region
end

---@param map table
---@return string?
function CustomMatchGroupInputMatchPage.getLength(map)
	if not map.matchInfo then return nil end
	return map.matchInfo.gameLengthMillis -- It's called millis but is in MM:SS format
end

---@param map table
---@return ValorantRoundData[]?
function CustomMatchGroupInputMatchPage.getRounds(map)
	if not map.matchInfo then return nil end

	local t1start = map.matchInfo.t1firstside
	local t1startot = map.matchInfo.o1t1firstside
	local nextOvertimeSide = t1startot
	return Array.map(map.roundDetails, function(round)
		local roundNumber = round.round_no
		-- TODO This is stupid, but it works until the API is improved
		local t1side, t2side
		if roundNumber <= 12 then
			t1side = t1start
			t2side = otherSide(t1start)
		elseif roundNumber <= 24 then
			t1side = otherSide(t1start)
			t2side = t1start
		else
			-- In overtime they switch sides every round
			t1side = nextOvertimeSide
			t2side = otherSide(nextOvertimeSide)
			nextOvertimeSide = otherSide(nextOvertimeSide)
		end

		---@type ValorantRoundData
		return {
			round = roundNumber,
			t1side = t1side,
			t2side = t2side,
			winningSide = round.round_winner,
			winBy = round.win_by,
		}
	end)
end

---@param map table
---@return string?
function CustomMatchGroupInputMatchPage.getPatch(map)
	if not map.matchInfo then return nil end
	return map.matchInfo.gameVersion
end

return CustomMatchGroupInputMatchPage
