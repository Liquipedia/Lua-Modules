local Match = require("Module:Match")
local Table = require("Module:Table")
local WikiSpecificBase = require('Module:Brkts/WikiSpecific/Base')
local getIconName = require("Module:IconName").luaGet
local json = require("Module:Json")
local utils = require("Module:LuaUtils")

local _frame

local ALLOWED_STATUSES = { "W", "FF", "DQ", "L" }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 20
local MAX_NUM_ROUNDS = 24

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local roundFunctions = {}
local opponentFunctions = {}

local p = Table.copy(WikiSpecificBase)

-- called from Module:MatchGroup
function p.processMatch(frame, match)
  	_frame = frame
  	if type(match) == "string" then
		match = json.parse(match)
	end
  	
  	-- process match
  	match = matchFunctions.getDateStuff(match)
  	match = matchFunctions.getOpponents(match)
  	match = matchFunctions.getTournamentVars(match)
  	match = matchFunctions.getVodStuff(match)
  	match = matchFunctions.getExtraData(match)
  
  	return match
end

-- called from Module:Match/Subobjects
function p.processMap(frame, map)
  	_frame = frame
  	if type(map) == "string" then
		map = json.parse(map)
	end
  	
  	-- process map
  	map = mapFunctions.getExtraData(map)
  	map = mapFunctions.getScoresAndWinner(map)
  	map = mapFunctions.getTournamentVars(map)
  	map = mapFunctions.getParticipantsData(map)

  	return map
end

-- called from Module:Match/Subobjects
function p.processOpponent(frame, opponent)
  	_frame = frame
  	if type(opponent) == "string" then
		opponent = json.parse(opponent)
	end
  
  	-- process opponent
  	if not utils.misc.isEmpty(opponent.template) then
		opponent.name = opponent.name or opponentFunctions.getTeamName(opponent.template)
	end
  	
  	return opponent
end

-- called from Module:Match/Subobjects
function p.processPlayer(frame, player)
  	_frame = frame
  	if type(player) == "string" then
		player = json.parse(player)
	end  	
  	return player
end

--
-- 
-- function to sort out winner/placements
function placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == "S"
	local op2norm = op2.status == "S"
	if op1norm then
		if op2norm then
		  	return tonumber(op1.score) > tonumber(op2.score)
		else return true end
	else
		if op2norm then return false
		elseif op1.status == "W" then return true
		elseif op1.status == "DQ" then return false
		elseif op2.status == "W" then return false
		elseif op2.status == "DQ" then return true
		else return true end
	end
end

--
-- match related functions
--
function matchFunctions.getDateStuff(match)
  	local lang = mw.getContentLanguage()
  	-- parse date string with abbr
  	if not utils.misc.isEmpty(match.date) then
		local matchString = match.date or ""
		local timezone = utils.string.split(
			utils.string.split(matchString, "data%-tz%=\"")[2] or "",
			"\"")[1] or ""
		local matchDate = utils.mw.explode(matchString, "<", 0):gsub("-", "")
		match.date = matchDate .. timezone
		match.dateexact = utils.string.contains(match.date, "%+") or utils.string.contains(match.date, "%-")
	else
		match.date = lang:formatDate('c', (utils.mw.varGet("tournament_date", "") or "") .. " + " .. utils.mw.varGet("num_missing_dates", "0") .. " second")
		match.dateexact = false
		utils.mw.varDefine("num_missing_dates", utils.mw.varGet("num_missing_dates", 0) + 1)
	end
  	return match
end

function matchFunctions.getTournamentVars(match)
	match.mode = utils.misc.emptyOr(match.mode, utils.mw.varGet("tournament_mode", "3v3"))
  	match.type = utils.misc.emptyOr(match.type, utils.mw.varGet("tournament_type"))
	match.tournament = utils.misc.emptyOr(match.tournament, utils.mw.varGet("tournament_name"))
  	match.tickername = utils.misc.emptyOr(match.tickername, utils.mw.varGet("tournament_ticker_name"))
  	match.shortname = utils.misc.emptyOr(match.shortname, utils.mw.varGet("tournament_shortname"))
  	match.series = utils.misc.emptyOr(match.series, utils.mw.varGet("tournament_series"))
  	match.icon = utils.misc.emptyOr(match.icon, utils.mw.varGet("tournament_icon"))
  	match.liquipediatier = utils.misc.emptyOr(match.liquipediatier, utils.mw.varGet("tournament_tier"))
  	return match
end

function matchFunctions.getVodStuff(match)
  	match.stream = match.stream or {}
  	match.stream = json.stringify({
		stream = utils.misc.emptyOr(match.stream.stream, utils.mw.varGet("stream")),
	  	twitch = utils.misc.emptyOr(match.stream.twitch or match.twitch, utils.mw.varGet("twitch")),
	  	twitch2 = utils.misc.emptyOr(match.stream.twitch2 or match.twitch2, utils.mw.varGet("twitch2")),
	  	afreeca = utils.misc.emptyOr(match.stream.afreeca or match.afreeca, utils.mw.varGet("afreeca")),
	  	afreecatv = utils.misc.emptyOr(match.stream.afreecatv or match.afreecatv, utils.mw.varGet("afreecatv")),
	  	dailymotion = utils.misc.emptyOr(match.stream.dailymotion or match.dailymotion, utils.mw.varGet("dailymotion")),
	  	douyu = utils.misc.emptyOr(match.stream.douyu or match.douyu, utils.mw.varGet("douyu")),
	  	smashcast = utils.misc.emptyOr(match.stream.smashcast or match.smashcast, utils.mw.varGet("smashcast")),
	  	youtube = utils.misc.emptyOr(match.stream.youtube or match.youtube, utils.mw.varGet("youtube"))
  	})
  	match.vod = utils.misc.emptyOr(match.vod, utils.mw.varGet("vod"))
  	
  	-- apply vodgames
  	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match["vodgame" .. index]
		if not utils.misc.isEmpty(vodgame) then
	  		local map = utils.misc.emptyOr(match["map" .. index], nil, {})
	  		if type(map) == "string" then
				map = json.parse(map)
			end
	  		map.vod = map.vod or vodgame
	  		match["map" .. index] = map
	  	end
	end
  	return match
end

function matchFunctions.getExtraData(match)
  	local opponent1 = match.opponent1 or {}
  	local opponent2 = match.opponent2 or {}
  	match.extradata = json.stringify({
	  matchsection = utils.mw.varGet("matchsection"),
	  team1icon = getIconName(opponent1.template or ""),
	  team2icon = getIconName(opponent2.template or ""),
	  lastgame = utils.mw.varGet("last_game"),
	  comment = match.comment,
	  octane = match.octane,
	  liquipediatier2 = utils.mw.varGet("tournament_tier2"),
	  isconverted = 0
	})
  	return match
end

function matchFunctions.getOpponents(args)
  	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		opponent = args["opponent" .. opponentIndex]
		if not utils.misc.isEmpty(opponent) then
			if type(opponent) == "string" then
				opponent = json.parse(opponent)
			end
			-- apply status
			if utils.misc.isNumeric(opponent.score) then
				opponent.status = "S"
				isScoreSet = true
			elseif utils.table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent
	  
	  		-- get players from vars for teams
	  		if opponent.type == "team" and not utils.misc.isEmpty(opponent.name) then
	  			args = matchFunctions.getPlayers(args, opponentIndex, opponent.name)
			end
	  	end
	end
	
	-- see if match should actually be finished if score is set
  	if isScoreSet and not utils.misc.readBool(args.finished) then
		local currentUnixTime = os.time(os.date("!*t"))
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', args.date))
		local threshold = args.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
	  		args.finished = true
	  	end
	end
	
	-- apply placements and winner if finshed
  	if utils.misc.readBool(args.finished) then
		local placement = 1
		for opponentIndex, opponent in utils.iter.spairs(opponents, placementSortFunction) do
	  		if placement == 1 then
				args.winner = opponentIndex
			end
	  		opponent.placement = placement
	  		args["opponent" .. opponentIndex] = opponent
	  		placement = placement + 1
	  	end
	-- only apply arg changes otherwise
 	else
		for opponentIndex, opponent in pairs(opponents) do
	  		args["opponent" .. opponentIndex] = opponent
	  	end
	end
  	return args
end

function matchFunctions.getPlayers(match, opponentIndex, teamName)
  	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		player = match["opponent" .. opponentIndex .. "_p" .. playerIndex] or {}
		if type(player) == "string" then
			player = json.parse(player)
		end
		player.name = player.name or utils.mw.varGet(teamName .. "_p" .. playerIndex)
		player.flag = player.flag or utils.mw.varGet(teamName .. "_p" .. playerIndex .. "flag")
		if not utils.table.isEmpty(player) then
			match["opponent" .. opponentIndex .. "_p" .. playerIndex] = player
		end
	end
	return match
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)
  	map.extradata = json.stringify({
	  ot = map.ot,
	  otlength = map.otlength,
	  comment = map.comment,
	  op1startside = map['op1_startside'],
	  half1score1 = map.half1score1,
	  half1score2 = map.half1score2,
	  half2score1 = map.half2score1,
	  half2score2 = map.half2score2,
	})
  	return map
end

function mapFunctions.getScoresAndWinner(map)
  	map.scores = {}
  	local indexedScores = {}
  	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map["score" .. scoreIndex]
		local obj = {}
		if not utils.misc.isEmpty(score) then
	  		if utils.misc.isNumeric(score) then
				obj.status = "S"
				obj.score = score
			elseif utils.table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
			end
			table.insert(map.scores, score)
	  		indexedScores[scoreIndex] = obj
	  	else
	  		break
	  	end
	end
  	for scoreIndex, score in utils.iter.spairs(indexedScores, placementSortFunction) do
		map.winner = scoreIndex
		break
  	end
  	return map
end

function mapFunctions.getTournamentVars(map)
	map.mode = utils.misc.emptyOr(map.mode, utils.mw.varGet("tournament_mode", "3v3"))
  	map.type = utils.misc.emptyOr(map.type, utils.mw.varGet("tournament_type"))
	map.tournament = utils.misc.emptyOr(map.tournament, utils.mw.varGet("tournament_name"))
  	map.tickername = utils.misc.emptyOr(map.tickername, utils.mw.varGet("tournament_ticker_name"))
  	map.shortname = utils.misc.emptyOr(map.shortname, utils.mw.varGet("tournament_shortname"))
  	map.series = utils.misc.emptyOr(map.series, utils.mw.varGet("tournament_series"))
  	map.icon = utils.misc.emptyOr(map.icon, utils.mw.varGet("tournament_icon"))
  	map.liquipediatier = utils.misc.emptyOr(map.liquipediatier, utils.mw.varGet("tournament_tier"))
  	return map
end

function mapFunctions.getParticipantsData(map)
  	local participants = map.participants or {}
  	if type(participants) == "string" then
		participants = json.parse(participants)
	end
  
  	-- fill in stats
  	for o = 1, MAX_NUM_OPPONENTS do
		for p = 1, MAX_NUM_PLAYERS do
	  		local participant = participants[o .. "_" .. p] or {}
	  		local opstring = "opponent" .. o .. "_p" .. p
			local stats = map[opstring .. "stats"]

			if stats ~= nil then
				stats = json.parse(stats)

				local kills = stats["kills"]
				local deaths = stats["deaths"]
				local assists = stats["assists"]
				local agent = stats["agent"]
				local averageCombatScore = stats["acs"]

				participant.kills = utils.misc.isEmpty(kills) and participant.kills or kills
				participant.deaths = utils.misc.isEmpty(deaths) and participant.deaths or deaths
				participant.assists = utils.misc.isEmpty(assists) and participant.assists or assists
				participant.agent = utils.misc.isEmpty(agent) and participant.agent or agent
				participant.acs = utils.misc.isEmpty(averageCombatScore) and participant.averagecombatscore or averageCombatScore

				if not utils.table.isEmpty(participant) then
					participants[o .. "_" .. p] = participant
				end
			end
	  	end
	end
  
  	map.participants = participants

	local rounds = {}

	for i = 1, MAX_NUM_ROUNDS do
		rounds[i] = roundFunctions.getRoundData(map['round' .. i])
	end

	map.rounds = rounds
  	return map
end

function roundFunctions.getRoundData(round)

	if round == nil then
		return nil
	end

	local participants = {}
	round = json.parse(round)

  	for o = 1, MAX_NUM_OPPONENTS do
		for p = 1, MAX_NUM_PLAYERS do
	  		local participant = {}
	  		local opstring = "opponent" .. o .. "_p" .. p
			local stats = round[opstring .. "stats"]

			if stats ~= nil then
				stats = json.parse(stats)

				local kills = stats["kills"]
				local score = stats["score"]
				local weapon = stats["weapon"]
				local buy = stats["buy"]
				local bank = stats["bank"]

				participant.kills = utils.misc.isEmpty(kills) and participant.kills or kills
				participant.score = utils.misc.isEmpty(score) and participant.score or score
				participant.weapon = utils.misc.isEmpty(weapon) and participant.weapon or weapon
				participant.buy = utils.misc.isEmpty(buy) and participant.buy or buy
				participant.bank = utils.misc.isEmpty(bank) and participant.bank or bank

				if not utils.table.isEmpty(participant) then
					participants[o .. "_" .. p] = participant
				end
			end
	  	end
	end

	round.buy = {
		round.buy1, round.buy2
	}

	round.bank = {
		round.bank1, round.bank2
	}

	round.kills = {
		round.kills1, round.kills2
	}

  	round.participants = participants
  	return round
end

--
-- opponent related functions
--
function opponentFunctions.getTeamName(template)
  	if template ~= nil then
		local team = utils.frame.expandTemplate(_frame, "Team", { template })
		team = team:gsub("%&", "")
		team = utils.string.split(team, "link=")[2]
		team = utils.string.split(team, "]]")[1]
		return team
	else
		return nil
	end
end

return p
