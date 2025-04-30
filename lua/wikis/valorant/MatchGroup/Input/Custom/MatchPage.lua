---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')

local CustomMatchGroupInputMatchPage = {}

---@class valorantMatchDataExtended: valorantMatchData
---@field matchid string
---@field vod string?

---@param mapInput {matchid: string?, reversed: string?, vod: string?, region: string?}
---@return dota2MatchDataExtended|table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end
	assert(mapInput.matchid, 'Numeric matchid expected, got ' .. mapInput.matchid)
	assert(mapInput.region, 'Region is required ')

	--local map = mw.ext.valorantdb.getDetails(mapInput.matchid, mapInput.region, Logic.readBool(mapInput.reversed))
	local map = CustomMatchGroupInputMatchPage.getMockData()

	assert(map and type(map) == 'table' and map.matchInfo, mapInput.matchid .. ' could not be retrieved.')
	-- Let's shift the array to start from 1
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

	---@cast map valorantMatchDataExtended
	map.matchid = mapInput.matchid
	map.vod = mapInput.vod

	return map
end

---@param map table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	local teamPlayers = map['players'][opponentIndex]
	if not teamPlayers then return end

	local function fetchLpPlayer(playerId)
		--- TODO
		return nil
	end
	local players = Array.map(teamPlayers.players, function(player)
		local playerData = fetchLpPlayer(player.riot_id) or {}
		return {
			player = playerData.pagename or player.riot_id,
			name = playerData.id or player.riot_id,
			agent = player.agent,
			asc = player.level,
			adr = nil,
			kast = nil,
			hs = nil,
			kills = player.kills,
			deaths = player.deaths,
			assists = player.assists,
		}
	end)
	return Array.sortBy(players, function(player)
		return player.asc or player.kills or player.player
	end)
end

---@param map table
---@param opponentIndex integer
---@return 'atk'|'def'|nil
function CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex)
	return map.matchInfo['t' .. opponentIndex .. 'firstside']
end

---@param map table
---@param side 'atk'|'def'|'otatk'|'otdef'
---@param opponentIndex integer
---@return integer?
function CustomMatchGroupInputMatchPage.getScoreFromRounds(map, side, opponentIndex)
	local teamColor = map.matchInfo['team' .. opponentIndex]
	if not teamColor then
		return nil
	end
	local sideData = map.matchInfo[teamColor]
	if not sideData then
		return nil
	end
	return sideData[side .. 'wins']
end

function CustomMatchGroupInputMatchPage.getMockData()
	return {
		["matchInfo"] = {
			["Blue"] = {
				["teamatkotwins"] = 0,
				["teamatkwins"] = 2,
				["teamdefotwins"] = 0,
				["teamdefwins"] = 8,
			},
			["Red"] = {
				["teamatkotwins"] = 0,
				["teamatkwins"] = 4,
				["teamdefotwins"] = 0,
				["teamdefwins"] = 9,
			},
			["gameLengthMillis"] = "32:42",
			["gameStartTime"] = "Apr 06, 2025 - 20:12 {{Abbr/UTC}}",
			["gameVersion"] = "10.06",
			["mapId"] = "Fracture",
			["o1t1firstside"] = "atk",
			["provisioningFlowId"] = "Matchmaking",
			["t1firstside"] = "atk",
			["team1"] = "Red",
			["team2"] = "Blue",
		},
		["players"] = {
			{
				{
					["acs"] = 420.21739130435,
					["agent"] = "waylay",
					["agent-id"] = "df1cb487-4902-002e-5c17-d28e83e78588",
					["assists"] = 4,
					["deaths"] = 14,
					["kills"] = 35,
					["puuid"] = "McKJGOGz2TbgXRK72NCf44ztcSTAf3rCxneTapvnnywtVPknEPcTPdICrmBOXF5diPPLKuhrk5_oXQ",
					["raw_riot_id"] = "PALO#minxi",
					["riot_id"] = "Palo",
					["score"] = 9665,
					["team"] = "Blue",
				},
				{
					["acs"] = 135.30434782609,
					["agent"] = "reyna",
					["agent-id"] = "a3bfb853-43b2-7238-a4f1-ad90e9e46bcc",
					["assists"] = 2,
					["deaths"] = 18,
					["kills"] = 10,
					["puuid"] = "tY4BAptpcu9IPhOPUvJtvLYasfVD7fIQRwFvFo4mC5B52j6Hh627EaQ4hgFYVsOvfhZ-6oyiyoypmQ",
					["raw_riot_id"] = "Ren",
					["riot_id"] = "Ren",
					["score"] = 3112,
					["team"] = "Blue",
				},
				{
					["acs"] = 203.78260869565,
					["agent"] = "vyse",
					["agent-id"] = "efba5359-4016-a1e5-7626-b1ae76895940",
					["assists"] = 4,
					["deaths"] = 17,
					["kills"] = 16,
					["puuid"] = "glAo5MP-HNTX_2He9uY244kWKZRUgFRXL_nnKADPQo4cV7xGal0ygg-Rt3MgEzhbxU4bJ7l6QO3Hxw",
					["raw_riot_id"] = "ruqia#love",
					["riot_id"] = "ruqia",
					["score"] = 4687,
					["team"] = "Blue",
				},
				{
					["acs"] = 153.13043478261,
					["agent"] = "clove",
					["agent-id"] = "1dbf2edd-4729-0984-3115-daa5eed44993",
					["assists"] = 11,
					["deaths"] = 23,
					["kills"] = 11,
					["puuid"] = "NFhG69aDRZ-bljSpV_XGrMJYm6GPk73F3i-OPKbPJMy9xxXzP5Gal8qWRyHf6RaXEPaBctksyr2V1g",
					["raw_riot_id"] = "xXTheBreakXVIII",
					["riot_id"] = "xXTheBreakXVIII",
					["score"] = 3522,
					["team"] = "Blue",
				},
				[0] = {
					["acs"] = 164,
					["agent"] = "breach",
					["agent-id"] = "5f8d3a7f-467b-97f3-062c-13acf203c006",
					["assists"] = 11,
					["deaths"] = 20,
					["kills"] = 12,
					["puuid"] = "RzXmNg-0wVBQtjyuBJW9cMaPj3JxjVUR1sxmEBcDgUV40_orJKHRsheJWBg_wcmALhs9QVmCR1sO_Q",
					["raw_riot_id"] = "NAIR#CSGO",
					["riot_id"] = "NAIR",
					["score"] = 3772,
					["team"] = "Blue",
				},
			},
			[0] = {
				{
					["acs"] = 229.47826086957,
					["agent"] = "jett",
					["agent-id"] = "add6443a-41bd-e414-f6ad-e58d267f4e95",
					["assists"] = 2,
					["deaths"] = 17,
					["kills"] = 21,
					["puuid"] = "spBPzNddRlm9u3NToKuzZbM9rI3oiHmWQiiYQ-ApP2n7NkaGevdM-JSpP1WYn8dhBpGv6UArZQ2tdg",
					["raw_riot_id"] = "SNT FoxxZ#wiff",
					["riot_id"] = "SNT FoxxZ",
					["score"] = 5278,
					["team"] = "Red",
				},
				{
					["acs"] = 351.4347826087,
					["agent"] = "chamber",
					["agent-id"] = "22697a3d-45bf-8dd7-4fec-84a9e28c69d7",
					["assists"] = 5,
					["deaths"] = 16,
					["kills"] = 27,
					["puuid"] = "xBDC36pxuv0MnMFw7eUC0OO1bDC_3s1n9yyYY5WNPrDeX-pCb7TLOQu30IVwMXnoTmse1K7jp42QCA",
					["raw_riot_id"] = "Swagfreak2164832#sybau",
					["riot_id"] = "Swagfreak2164832",
					["score"] = 8083,
					["team"] = "Red",
				},
				{
					["acs"] = 127.34782608696,
					["agent"] = "breach",
					["agent-id"] = "5f8d3a7f-467b-97f3-062c-13acf203c006",
					["assists"] = 5,
					["deaths"] = 16,
					["kills"] = 12,
					["puuid"] = "KDe5gHDQD8Q3NRggOz0tSRFCouYwQMBC6cs3hXSW9EMM-FhmLOwPczVjHDfZfIxtHZrGoE337hPenA",
					["raw_riot_id"] = "ZED neyZy",
					["riot_id"] = "ZED neyZ",
					["score"] = 2929,
					["team"] = "Red",
				},
				{
					["acs"] = 202.4347826087,
					["agent"] = "clove",
					["agent-id"] = "1dbf2edd-4729-0984-3115-daa5eed44993",
					["assists"] = 3,
					["deaths"] = 20,
					["kills"] = 18,
					["puuid"] = "BZFLavSaflgWegdx-nte11Brw6tYv4AGogjAJwSFYytoWKmmQ5KSQsVtnuXrzvLSIZ-PxCJ8FtGsXQ",
					["raw_riot_id"] = "나는 당신을 이겼다",
					["riot_id"] = "나는 당신을 이겼다",
					["score"] = 4656,
					["team"] = "Red",
				},
				[0] = {
					["acs"] = 196.95652173913,
					["agent"] = "phoenix",
					["agent-id"] = "eb93336a-449b-9c1b-0a54-a891f7921d69",
					["assists"] = 9,
					["deaths"] = 15,
					["kills"] = 14,
					["puuid"] = "m8AsmAJtw17hLUowP-p54A8kYCnXATartpyS5zoQyQuZIA7e6zPSb2pwRnLze8IQrZebir7E576ihg",
					["raw_riot_id"] = "aspas final boss#ASP",
					["riot_id"] = "aspas final boss",
					["score"] = 4530,
					["team"] = "Red",
				},
			},
		},
		["roundDetails"] = {
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1450,
						["buy"] = 750,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 1600,
						["buy"] = 400,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 1950,
						["buy"] = 0,
						["kills"] = 1,
						["score"] = 261,
					},
					["1_4"] = {
						["bank"] = 1900,
						["buy"] = 500,
						["kills"] = 1,
						["score"] = 275,
					},
					["1_5"] = {
						["bank"] = 1450,
						["buy"] = 1200,
						["kills"] = 1,
						["score"] = 280,
					},
					["2_1"] = {
						["bank"] = 0,
						["buy"] = 3850,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_2"] = {
						["bank"] = 0,
						["buy"] = 3100,
						["kills"] = 0,
						["score"] = 119,
					},
					["2_3"] = {
						["bank"] = 0,
						["buy"] = 3400,
						["kills"] = 2,
						["score"] = 430,
					},
					["2_4"] = {
						["bank"] = 3100,
						["buy"] = 1400,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 650,
						["buy"] = 2850,
						["kills"] = 3,
						["score"] = 701,
					},
				},
				["round_no"] = 2,
				["round_winner"] = "def",
				["t1_bank"] = 8350,
				["t1_buy"] = 2850,
				["t1_kills"] = 3,
				["t2_bank"] = 3750,
				["t2_buy"] = 14600,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 400,
						["buy"] = 4050,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 100,
						["buy"] = 3900,
						["kills"] = 3,
						["score"] = 888,
					},
					["1_3"] = {
						["bank"] = 200,
						["buy"] = 4350,
						["kills"] = 1,
						["score"] = 279,
					},
					["1_4"] = {
						["bank"] = 0,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 150,
						["buy"] = 4300,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 2400,
						["buy"] = 3300,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_2"] = {
						["bank"] = 2400,
						["buy"] = 1900,
						["kills"] = 0,
						["score"] = 25,
					},
					["2_3"] = {
						["bank"] = 2800,
						["buy"] = 4000,
						["kills"] = 3,
						["score"] = 861,
					},
					["2_4"] = {
						["bank"] = 2050,
						["buy"] = 4400,
						["kills"] = 1,
						["score"] = 418,
					},
					["2_5"] = {
						["bank"] = 2950,
						["buy"] = 2750,
						["kills"] = 1,
						["score"] = 80,
					},
				},
				["round_no"] = 3,
				["round_winner"] = "def",
				["t1_bank"] = 850,
				["t1_buy"] = 21200,
				["t1_kills"] = 4,
				["t2_bank"] = 12600,
				["t2_buy"] = 16350,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1950,
						["buy"] = 1950,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 1800,
						["buy"] = 1800,
						["kills"] = 1,
						["score"] = 254,
					},
					["1_3"] = {
						["bank"] = 2000,
						["buy"] = 1500,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 1900,
						["buy"] = 1700,
						["kills"] = 1,
						["score"] = 280,
					},
					["1_5"] = {
						["bank"] = 1350,
						["buy"] = 1950,
						["kills"] = 0,
						["score"] = 137,
					},
					["2_1"] = {
						["bank"] = 1000,
						["buy"] = 4200,
						["kills"] = 1,
						["score"] = 220,
					},
					["2_2"] = {
						["bank"] = 1000,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 280,
					},
					["2_3"] = {
						["bank"] = 100,
						["buy"] = 6300,
						["kills"] = 3,
						["score"] = 824,
					},
					["2_4"] = {
						["bank"] = 950,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 4350,
						["buy"] = 5100,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 4,
				["round_winner"] = "def",
				["t1_bank"] = 9000,
				["t1_buy"] = 8900,
				["t1_kills"] = 2,
				["t2_bank"] = 7400,
				["t2_buy"] = 24850,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 950,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 570,
					},
					["1_2"] = {
						["bank"] = 450,
						["buy"] = 4450,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 1000,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 259,
					},
					["1_4"] = {
						["bank"] = 3600,
						["buy"] = 1800,
						["kills"] = 2,
						["score"] = 570,
					},
					["1_5"] = {
						["bank"] = 100,
						["buy"] = 4550,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 2850,
						["buy"] = 5000,
						["kills"] = 0,
						["score"] = 114,
					},
					["2_2"] = {
						["bank"] = 2950,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 166,
					},
					["2_3"] = {
						["bank"] = 2100,
						["buy"] = 6600,
						["kills"] = 1,
						["score"] = 300,
					},
					["2_4"] = {
						["bank"] = 900,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 64,
					},
					["2_5"] = {
						["bank"] = 3150,
						["buy"] = 5100,
						["kills"] = 0,
						["score"] = 70,
					},
				},
				["round_no"] = 5,
				["round_winner"] = "atk",
				["t1_bank"] = 6100,
				["t1_buy"] = 20050,
				["t1_kills"] = 5,
				["t2_bank"] = 11950,
				["t2_buy"] = 25950,
				["t2_kills"] = 2,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 4250,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 275,
					},
					["1_2"] = {
						["bank"] = 2350,
						["buy"] = 1550,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 2800,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 254,
					},
					["1_4"] = {
						["bank"] = 3200,
						["buy"] = 4900,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 2200,
						["buy"] = 4750,
						["kills"] = 1,
						["score"] = 326,
					},
					["2_1"] = {
						["bank"] = 1250,
						["buy"] = 3650,
						["kills"] = 1,
						["score"] = 180,
					},
					["2_2"] = {
						["bank"] = 1050,
						["buy"] = 4000,
						["kills"] = 1,
						["score"] = 425,
					},
					["2_3"] = {
						["bank"] = 900,
						["buy"] = 3900,
						["kills"] = 3,
						["score"] = 740,
					},
					["2_4"] = {
						["bank"] = 1450,
						["buy"] = 1700,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 650,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 228,
					},
				},
				["round_no"] = 6,
				["round_winner"] = "def",
				["t1_bank"] = 14800,
				["t1_buy"] = 20450,
				["t1_kills"] = 3,
				["t2_bank"] = 5300,
				["t2_buy"] = 18050,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 2100,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 633,
					},
					["1_2"] = {
						["bank"] = 150,
						["buy"] = 4250,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 500,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 35,
					},
					["1_4"] = {
						["bank"] = 1200,
						["buy"] = 4700,
						["kills"] = 0,
						["score"] = 240,
					},
					["1_5"] = {
						["bank"] = 0,
						["buy"] = 4750,
						["kills"] = 2,
						["score"] = 390,
					},
					["2_1"] = {
						["bank"] = 1200,
						["buy"] = 4100,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_2"] = {
						["bank"] = 100,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 220,
					},
					["2_3"] = {
						["bank"] = 2600,
						["buy"] = 4500,
						["kills"] = 2,
						["score"] = 490,
					},
					["2_4"] = {
						["bank"] = 150,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 605,
					},
					["2_5"] = {
						["bank"] = 1950,
						["buy"] = 4800,
						["kills"] = 1,
						["score"] = 280,
					},
				},
				["round_no"] = 7,
				["round_winner"] = "def",
				["t1_bank"] = 3950,
				["t1_buy"] = 22950,
				["t1_kills"] = 4,
				["t2_bank"] = 6000,
				["t2_buy"] = 22650,
				["t2_kills"] = 6,
				["win_by"] = "defuse",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1750,
						["buy"] = 4050,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 1650,
						["buy"] = 1350,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 1900,
						["buy"] = 1500,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 2700,
						["buy"] = 2000,
						["kills"] = 0,
						["score"] = 55,
					},
					["1_5"] = {
						["bank"] = 1300,
						["buy"] = 2250,
						["kills"] = 0,
						["score"] = 55,
					},
					["2_1"] = {
						["bank"] = 150,
						["buy"] = 3750,
						["kills"] = 1,
						["score"] = 190,
					},
					["2_2"] = {
						["bank"] = 800,
						["buy"] = 2500,
						["kills"] = 0,
						["score"] = 25,
					},
					["2_3"] = {
						["bank"] = 1500,
						["buy"] = 4800,
						["kills"] = 4,
						["score"] = 1185,
					},
					["2_4"] = {
						["bank"] = 1950,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 550,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 8,
				["round_winner"] = "def",
				["t1_bank"] = 9300,
				["t1_buy"] = 11150,
				["t1_kills"] = 0,
				["t2_bank"] = 4950,
				["t2_buy"] = 20500,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 600,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 420,
					},
					["1_2"] = {
						["bank"] = 250,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 280,
					},
					["1_3"] = {
						["bank"] = 700,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 179,
					},
					["1_4"] = {
						["bank"] = 1400,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 300,
					},
					["1_5"] = {
						["bank"] = 150,
						["buy"] = 4300,
						["kills"] = 1,
						["score"] = 360,
					},
					["2_1"] = {
						["bank"] = 2550,
						["buy"] = 3850,
						["kills"] = 1,
						["score"] = 260,
					},
					["2_2"] = {
						["bank"] = 200,
						["buy"] = 5400,
						["kills"] = 2,
						["score"] = 740,
					},
					["2_3"] = {
						["bank"] = 4000,
						["buy"] = 5300,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 4800,
						["buy"] = 5450,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_5"] = {
						["bank"] = 3550,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 9,
				["round_winner"] = "atk",
				["t1_bank"] = 3100,
				["t1_buy"] = 22600,
				["t1_kills"] = 6,
				["t2_bank"] = 15100,
				["t2_buy"] = 24800,
				["t2_kills"] = 3,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 250,
						["buy"] = 4650,
						["kills"] = 4,
						["score"] = 948,
					},
					["1_2"] = {
						["bank"] = 100,
						["buy"] = 3850,
						["kills"] = 1,
						["score"] = 313,
					},
					["1_3"] = {
						["bank"] = 3500,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 700,
						["buy"] = 4700,
						["kills"] = 0,
						["score"] = 110,
					},
					["1_5"] = {
						["bank"] = 3050,
						["buy"] = 4750,
						["kills"] = 0,
						["score"] = 52,
					},
					["2_1"] = {
						["bank"] = 250,
						["buy"] = 3900,
						["kills"] = 0,
						["score"] = 135,
					},
					["2_2"] = {
						["bank"] = 700,
						["buy"] = 2500,
						["kills"] = 1,
						["score"] = 254,
					},
					["2_3"] = {
						["bank"] = 800,
						["buy"] = 5700,
						["kills"] = 1,
						["score"] = 189,
					},
					["2_4"] = {
						["bank"] = 2400,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 70,
					},
					["2_5"] = {
						["bank"] = 1550,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 10,
				["round_winner"] = "atk",
				["t1_bank"] = 7600,
				["t1_buy"] = 22550,
				["t1_kills"] = 5,
				["t2_bank"] = 5700,
				["t2_buy"] = 21550,
				["t2_kills"] = 2,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 2750,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 215,
					},
					["1_2"] = {
						["bank"] = 2050,
						["buy"] = 4450,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 2400,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 25,
					},
					["1_4"] = {
						["bank"] = 3500,
						["buy"] = 4900,
						["kills"] = 2,
						["score"] = 565,
					},
					["1_5"] = {
						["bank"] = 3100,
						["buy"] = 4750,
						["kills"] = 1,
						["score"] = 315,
					},
					["2_1"] = {
						["bank"] = 950,
						["buy"] = 1200,
						["kills"] = 0,
						["score"] = 110,
					},
					["2_2"] = {
						["bank"] = 150,
						["buy"] = 3150,
						["kills"] = 1,
						["score"] = 300,
					},
					["2_3"] = {
						["bank"] = 100,
						["buy"] = 3300,
						["kills"] = 3,
						["score"] = 890,
					},
					["2_4"] = {
						["bank"] = 500,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 260,
					},
					["2_5"] = {
						["bank"] = 1950,
						["buy"] = 2400,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 11,
				["round_winner"] = "atk",
				["t1_bank"] = 13800,
				["t1_buy"] = 23350,
				["t1_kills"] = 4,
				["t2_bank"] = 3650,
				["t2_buy"] = 14700,
				["t2_kills"] = 5,
				["win_by"] = "explosion",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 2200,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 900,
						["buy"] = 4450,
						["kills"] = 0,
						["score"] = 120,
					},
					["1_3"] = {
						["bank"] = 4000,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 3100,
						["buy"] = 4900,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 2100,
						["buy"] = 4750,
						["kills"] = 1,
						["score"] = 395,
					},
					["2_1"] = {
						["bank"] = 50,
						["buy"] = 3300,
						["kills"] = 1,
						["score"] = 220,
					},
					["2_2"] = {
						["bank"] = 100,
						["buy"] = 3150,
						["kills"] = 2,
						["score"] = 550,
					},
					["2_3"] = {
						["bank"] = 100,
						["buy"] = 4500,
						["kills"] = 1,
						["score"] = 300,
					},
					["2_4"] = {
						["bank"] = 100,
						["buy"] = 3650,
						["kills"] = 0,
						["score"] = 75,
					},
					["2_5"] = {
						["bank"] = 150,
						["buy"] = 5100,
						["kills"] = 1,
						["score"] = 279,
					},
				},
				["round_no"] = 12,
				["round_winner"] = "atk",
				["t1_bank"] = 12300,
				["t1_buy"] = 23350,
				["t1_kills"] = 1,
				["t2_bank"] = 500,
				["t2_buy"] = 19700,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 150,
						["buy"] = 800,
						["kills"] = 0,
						["score"] = 30,
					},
					["1_2"] = {
						["bank"] = 0,
						["buy"] = 800,
						["kills"] = 4,
						["score"] = 944,
					},
					["1_3"] = {
						["bank"] = 50,
						["buy"] = 750,
						["kills"] = 1,
						["score"] = 245,
					},
					["1_4"] = {
						["bank"] = 0,
						["buy"] = 600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 100,
						["buy"] = 950,
						["kills"] = 0,
						["score"] = 55,
					},
					["2_1"] = {
						["bank"] = 0,
						["buy"] = 600,
						["kills"] = 2,
						["score"] = 551,
					},
					["2_2"] = {
						["bank"] = 100,
						["buy"] = 700,
						["kills"] = 1,
						["score"] = 235,
					},
					["2_3"] = {
						["bank"] = 0,
						["buy"] = 800,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 50,
						["buy"] = 900,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 150,
						["buy"] = 850,
						["kills"] = 0,
						["score"] = 63,
					},
				},
				["round_no"] = 13,
				["round_winner"] = "def",
				["t1_bank"] = 300,
				["t1_buy"] = 3900,
				["t1_kills"] = 5,
				["t2_bank"] = 300,
				["t2_buy"] = 3850,
				["t2_kills"] = 3,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 100,
						["buy"] = 3200,
						["kills"] = 1,
						["score"] = 129,
					},
					["1_2"] = {
						["bank"] = 2250,
						["buy"] = 2350,
						["kills"] = 1,
						["score"] = 265,
					},
					["1_3"] = {
						["bank"] = 1800,
						["buy"] = 2200,
						["kills"] = 1,
						["score"] = 175,
					},
					["1_4"] = {
						["bank"] = 0,
						["buy"] = 3400,
						["kills"] = 2,
						["score"] = 530,
					},
					["1_5"] = {
						["bank"] = 50,
						["buy"] = 3300,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 1500,
						["buy"] = 950,
						["kills"] = 2,
						["score"] = 524,
					},
					["2_2"] = {
						["bank"] = 1400,
						["buy"] = 1000,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 1100,
						["buy"] = 1100,
						["kills"] = 0,
						["score"] = 55,
					},
					["2_4"] = {
						["bank"] = 1800,
						["buy"] = 500,
						["kills"] = 0,
						["score"] = 104,
					},
					["2_5"] = {
						["bank"] = 950,
						["buy"] = 1500,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 14,
				["round_winner"] = "def",
				["t1_bank"] = 4200,
				["t1_buy"] = 14450,
				["t1_kills"] = 5,
				["t2_bank"] = 6750,
				["t2_buy"] = 5050,
				["t2_kills"] = 2,
				["win_by"] = "defuse",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 2700,
						["buy"] = 4000,
						["kills"] = 1,
						["score"] = 294,
					},
					["1_2"] = {
						["bank"] = 1350,
						["buy"] = 4450,
						["kills"] = 2,
						["score"] = 471,
					},
					["1_3"] = {
						["bank"] = 4000,
						["buy"] = 2500,
						["kills"] = 1,
						["score"] = 144,
					},
					["1_4"] = {
						["bank"] = 2000,
						["buy"] = 4200,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 2450,
						["buy"] = 4700,
						["kills"] = 1,
						["score"] = 446,
					},
					["2_1"] = {
						["bank"] = 350,
						["buy"] = 4200,
						["kills"] = 1,
						["score"] = 313,
					},
					["2_2"] = {
						["bank"] = 100,
						["buy"] = 4000,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_3"] = {
						["bank"] = 200,
						["buy"] = 3600,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 200,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 551,
					},
					["2_5"] = {
						["bank"] = 550,
						["buy"] = 3500,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 15,
				["round_winner"] = "def",
				["t1_bank"] = 12500,
				["t1_buy"] = 19850,
				["t1_kills"] = 5,
				["t2_bank"] = 1400,
				["t2_buy"] = 19950,
				["t2_kills"] = 3,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1600,
						["buy"] = 4650,
						["kills"] = 2,
						["score"] = 580,
					},
					["1_2"] = {
						["bank"] = 3750,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 130,
					},
					["1_3"] = {
						["bank"] = 2500,
						["buy"] = 5400,
						["kills"] = 1,
						["score"] = 254,
					},
					["1_4"] = {
						["bank"] = 3800,
						["buy"] = 6500,
						["kills"] = 1,
						["score"] = 300,
					},
					["1_5"] = {
						["bank"] = 1300,
						["buy"] = 4750,
						["kills"] = 0,
						["score"] = 84,
					},
					["2_1"] = {
						["bank"] = 2050,
						["buy"] = 1700,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_2"] = {
						["bank"] = 1550,
						["buy"] = 1900,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 1300,
						["buy"] = 2100,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 1950,
						["buy"] = 1950,
						["kills"] = 1,
						["score"] = 220,
					},
					["2_5"] = {
						["bank"] = 1200,
						["buy"] = 2650,
						["kills"] = 2,
						["score"] = 710,
					},
				},
				["round_no"] = 16,
				["round_winner"] = "def",
				["t1_bank"] = 12950,
				["t1_buy"] = 25750,
				["t1_kills"] = 5,
				["t2_bank"] = 8050,
				["t2_buy"] = 10300,
				["t2_kills"] = 3,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 950,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 2050,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 115,
					},
					["1_3"] = {
						["bank"] = 1800,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 5800,
						["buy"] = 6700,
						["kills"] = 5,
						["score"] = 1525,
					},
					["1_5"] = {
						["bank"] = 2850,
						["buy"] = 4750,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 1050,
						["buy"] = 4200,
						["kills"] = 0,
						["score"] = 65,
					},
					["2_2"] = {
						["bank"] = 900,
						["buy"] = 4000,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 900,
						["buy"] = 3900,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 1000,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_5"] = {
						["bank"] = 150,
						["buy"] = 4550,
						["kills"] = 1,
						["score"] = 298,
					},
				},
				["round_no"] = 17,
				["round_winner"] = "def",
				["t1_bank"] = 13450,
				["t1_buy"] = 25150,
				["t1_kills"] = 6,
				["t2_bank"] = 4000,
				["t2_buy"] = 21300,
				["t2_kills"] = 1,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 3550,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 65,
					},
					["1_2"] = {
						["bank"] = 5250,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 315,
					},
					["1_3"] = {
						["bank"] = 3800,
						["buy"] = 4600,
						["kills"] = 2,
						["score"] = 519,
					},
					["1_4"] = {
						["bank"] = 4100,
						["buy"] = 6500,
						["kills"] = 1,
						["score"] = 195,
					},
					["1_5"] = {
						["bank"] = 5600,
						["buy"] = 4750,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 2550,
						["buy"] = 1700,
						["kills"] = 2,
						["score"] = 590,
					},
					["2_2"] = {
						["bank"] = 250,
						["buy"] = 4000,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_3"] = {
						["bank"] = 200,
						["buy"] = 3900,
						["kills"] = 2,
						["score"] = 390,
					},
					["2_4"] = {
						["bank"] = 200,
						["buy"] = 4050,
						["kills"] = 0,
						["score"] = 80,
					},
					["2_5"] = {
						["bank"] = 1300,
						["buy"] = 2400,
						["kills"] = 1,
						["score"] = 299,
					},
				},
				["round_no"] = 18,
				["round_winner"] = "atk",
				["t1_bank"] = 22300,
				["t1_buy"] = 24950,
				["t1_kills"] = 4,
				["t2_bank"] = 4500,
				["t2_buy"] = 16050,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1150,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 257,
					},
					["1_2"] = {
						["bank"] = 3450,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 170,
					},
					["1_3"] = {
						["bank"] = 1750,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 300,
						["buy"] = 6500,
						["kills"] = 2,
						["score"] = 630,
					},
					["1_5"] = {
						["bank"] = 3350,
						["buy"] = 4750,
						["kills"] = 1,
						["score"] = 318,
					},
					["2_1"] = {
						["bank"] = 2150,
						["buy"] = 4400,
						["kills"] = 1,
						["score"] = 360,
					},
					["2_2"] = {
						["bank"] = 400,
						["buy"] = 3150,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 2300,
						["buy"] = 4500,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_4"] = {
						["bank"] = 50,
						["buy"] = 3800,
						["kills"] = 1,
						["score"] = 300,
					},
					["2_5"] = {
						["bank"] = 400,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 19,
				["round_winner"] = "def",
				["t1_bank"] = 10000,
				["t1_buy"] = 24950,
				["t1_kills"] = 5,
				["t2_bank"] = 5300,
				["t2_buy"] = 20650,
				["t2_kills"] = 2,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 3200,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 2550,
						["buy"] = 4450,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_3"] = {
						["bank"] = 4750,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 2500,
						["buy"] = 6500,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_5"] = {
						["bank"] = 3300,
						["buy"] = 4750,
						["kills"] = 1,
						["score"] = 250,
					},
					["2_1"] = {
						["bank"] = 950,
						["buy"] = 3800,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_2"] = {
						["bank"] = 1100,
						["buy"] = 1400,
						["kills"] = 1,
						["score"] = 278,
					},
					["2_3"] = {
						["bank"] = 900,
						["buy"] = 3900,
						["kills"] = 4,
						["score"] = 1131,
					},
					["2_4"] = {
						["bank"] = 1350,
						["buy"] = 950,
						["kills"] = 1,
						["score"] = 215,
					},
					["2_5"] = {
						["bank"] = 550,
						["buy"] = 2400,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 20,
				["round_winner"] = "atk",
				["t1_bank"] = 16300,
				["t1_buy"] = 24950,
				["t1_kills"] = 1,
				["t2_bank"] = 4850,
				["t2_buy"] = 12450,
				["t2_kills"] = 6,
				["win_by"] = "elimination",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1050,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 550,
						["buy"] = 4450,
						["kills"] = 1,
						["score"] = 260,
					},
					["1_3"] = {
						["bank"] = 2300,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 25,
					},
					["1_4"] = {
						["bank"] = 2900,
						["buy"] = 2100,
						["kills"] = 3,
						["score"] = 920,
					},
					["1_5"] = {
						["bank"] = 1250,
						["buy"] = 4550,
						["kills"] = 1,
						["score"] = 220,
					},
					["2_1"] = {
						["bank"] = 3800,
						["buy"] = 4100,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_2"] = {
						["bank"] = 2900,
						["buy"] = 5400,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 3400,
						["buy"] = 4500,
						["kills"] = 2,
						["score"] = 630,
					},
					["2_4"] = {
						["bank"] = 350,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 260,
					},
					["2_5"] = {
						["bank"] = 2350,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 74,
					},
				},
				["round_no"] = 21,
				["round_winner"] = "def",
				["t1_bank"] = 8050,
				["t1_buy"] = 20350,
				["t1_kills"] = 5,
				["t2_bank"] = 12800,
				["t2_buy"] = 23450,
				["t2_kills"] = 3,
				["win_by"] = "defuse",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 2900,
						["buy"] = 4650,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 2550,
						["buy"] = 4450,
						["kills"] = 2,
						["score"] = 460,
					},
					["1_3"] = {
						["bank"] = 1200,
						["buy"] = 4600,
						["kills"] = 1,
						["score"] = 275,
					},
					["1_4"] = {
						["bank"] = 600,
						["buy"] = 6800,
						["kills"] = 3,
						["score"] = 880,
					},
					["1_5"] = {
						["bank"] = 1350,
						["buy"] = 4750,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_1"] = {
						["bank"] = 1600,
						["buy"] = 4700,
						["kills"] = 1,
						["score"] = 315,
					},
					["2_2"] = {
						["bank"] = 850,
						["buy"] = 4250,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 1800,
						["buy"] = 4500,
						["kills"] = 2,
						["score"] = 650,
					},
					["2_4"] = {
						["bank"] = 600,
						["buy"] = 2550,
						["kills"] = 0,
						["score"] = 50,
					},
					["2_5"] = {
						["bank"] = 150,
						["buy"] = 4800,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 22,
				["round_winner"] = "def",
				["t1_bank"] = 8600,
				["t1_buy"] = 25250,
				["t1_kills"] = 6,
				["t2_bank"] = 5000,
				["t2_buy"] = 20800,
				["t2_kills"] = 3,
				["win_by"] = "defuse",
			},
			{
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 1850,
						["buy"] = 4650,
						["kills"] = 1,
						["score"] = 240,
					},
					["1_2"] = {
						["bank"] = 4550,
						["buy"] = 5250,
						["kills"] = 1,
						["score"] = 235,
					},
					["1_3"] = {
						["bank"] = 300,
						["buy"] = 4600,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 2700,
						["buy"] = 6800,
						["kills"] = 1,
						["score"] = 280,
					},
					["1_5"] = {
						["bank"] = 450,
						["buy"] = 4750,
						["kills"] = 2,
						["score"] = 595,
					},
					["2_1"] = {
						["bank"] = 250,
						["buy"] = 4400,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_2"] = {
						["bank"] = 0,
						["buy"] = 3800,
						["kills"] = 0,
						["score"] = 0,
					},
					["2_3"] = {
						["bank"] = 400,
						["buy"] = 4500,
						["kills"] = 0,
						["score"] = 40,
					},
					["2_4"] = {
						["bank"] = 100,
						["buy"] = 3800,
						["kills"] = 0,
						["score"] = 70,
					},
					["2_5"] = {
						["bank"] = 250,
						["buy"] = 3000,
						["kills"] = 0,
						["score"] = 0,
					},
				},
				["round_no"] = 23,
				["round_winner"] = "def",
				["t1_bank"] = 9850,
				["t1_buy"] = 26050,
				["t1_kills"] = 5,
				["t2_bank"] = 1000,
				["t2_buy"] = 19500,
				["t2_kills"] = 0,
				["win_by"] = "elimination",
			},
			[0] = {
				["playerDetails"] = {
					["1_1"] = {
						["bank"] = 150,
						["buy"] = 800,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_2"] = {
						["bank"] = 100,
						["buy"] = 700,
						["kills"] = 0,
						["score"] = 58,
					},
					["1_3"] = {
						["bank"] = 50,
						["buy"] = 750,
						["kills"] = 0,
						["score"] = 0,
					},
					["1_4"] = {
						["bank"] = 0,
						["buy"] = 600,
						["kills"] = 2,
						["score"] = 428,
					},
					["1_5"] = {
						["bank"] = 150,
						["buy"] = 900,
						["kills"] = 1,
						["score"] = 252,
					},
					["2_1"] = {
						["bank"] = 0,
						["buy"] = 800,
						["kills"] = 2,
						["score"] = 420,
					},
					["2_2"] = {
						["bank"] = 100,
						["buy"] = 700,
						["kills"] = 0,
						["score"] = 75,
					},
					["2_3"] = {
						["bank"] = 0,
						["buy"] = 800,
						["kills"] = 2,
						["score"] = 560,
					},
					["2_4"] = {
						["bank"] = 50,
						["buy"] = 900,
						["kills"] = 1,
						["score"] = 140,
					},
					["2_5"] = {
						["bank"] = 100,
						["buy"] = 900,
						["kills"] = 0,
						["score"] = 30,
					},
				},
				["round_no"] = 1,
				["round_winner"] = "def",
				["t1_bank"] = 450,
				["t1_buy"] = 3750,
				["t1_kills"] = 3,
				["t2_bank"] = 250,
				["t2_buy"] = 4100,
				["t2_kills"] = 5,
				["win_by"] = "elimination",
			},
		},
		["teams"] = {
			{
				["roundsWon"] = 10,
				["teamId"] = "Blue",
				["won"] = 0,
			},
			[0] = {
				["roundsWon"] = 13,
				["teamId"] = "Red",
				["won"] = 1,
			},
		},
	}
end

return CustomMatchGroupInputMatchPage
