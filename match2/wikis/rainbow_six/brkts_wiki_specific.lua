-- TODO: Add more matchs resulttype and walkover
-- TODO: Add Best of X handling for upcoming/ongoing matches
-- TODO: Add automatic match score generation based on map winners

local Table = require("Module:Table")
local WikiSpecificBase = require('Module:Brkts/WikiSpecific/Base')
local Json = require("Module:Json")
local Logic = require("Module:Logic")
local TypeUtil = require("Module:TypeUtil")
local String = require("Module:StringUtils")
local Variables = require("Module:Variables")

local ALLOWED_STATUSES = { "W", "FF", "DQ", "L", "D" }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 9
local MAX_NUM_MAPS = 9

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local p = Table.copy(WikiSpecificBase)

-- called from Module:MatchGroup
function p.processMatch(_, match)
	if type(match) == "string" then
		match = Json.parse(match)
	end
	mw.logObject(match)

	-- process match
	match = matchFunctions.getDateStuff(match)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function p.processMap(_, map)
	mw.logObject(map)
	if type(map) == "string" then
		map = Json.parse(map)
	end

	-- process map
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

-- called from Module:Match/Subobjects
function p.processOpponent(_, opponent)
	if type(opponent) == "string" then
		opponent = Json.parse(opponent)
	end

	-- process opponent
	if not Logic.isEmpty(opponent.template) and
		string.lower(opponent.template) == 'bye' then
			opponent.name = 'BYE'
			opponent.type = 'literal'
	end

	return opponent
end

-- called from Module:Match/Subobjects
function p.processPlayer(_, player)
	if type(player) == "string" then
		player = Json.parse(player)
	end
	return player
end

--
--
-- function to sort out winner/placements
function p.placementSortFunction(table, key1, key2)
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
--
-- function to check for draws
function p.placementCheckDraw(table)
	local last
	for _, scoreInfo in pairs(table) do
		if scoreInfo.status ~= 'S' and scoreInfo.status ~= 'D' then
			return false
		end
		if last and last ~= scoreInfo.score then
			return false
		else
			last = scoreInfo.score
		end
	end

	return true
end

-- Check if any team has a none-standard status
function p.placementCheckSpecialStatus(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfiets
function p.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
function p.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
function p.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
function p.getDefaultWinner(table)
	for index, scoreInfo in pairs(table) do
		if scoreInfo.status == 'W' then
			return index
		end
	end
	return -1
end

--
-- match related functions
--
function matchFunctions.getDateStuff(match)
	local lang = mw.getContentLanguage()
	-- parse date string with abbr
	if not Logic.isEmpty(match.date) then
		local matchString = match.date or ""
		local timezone = String.split(
			String.split(matchString, "data%-tz%=\"")[2] or "",
			"\"")[1] or String.split(
			String.split(matchString, "data%-tz%=\'")[2] or "",
			"\'")[1] or ""
		local matchDate = String.explode(matchString, "<", 0):gsub("-", "")
		match.date = matchDate .. timezone
		match.dateexact = String.contains(match.date, "%+") or String.contains(match.date, "%-")
	else
		match.date = lang:formatDate(
			'c',
			(Variables.varDefault("tournament_date", "") or "")
				.. " + " .. Variables.varDefault("num_missing_dates", "0") .. " second"
		)
		match.dateexact = false
		Variables.varDefine("num_missing_dates", Variables.varDefault("num_missing_dates", 0) + 1)
	end
	return match
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault("tournament_mode", "team"))
	match.type = Logic.emptyOr(match.type, Variables.varDefault("tournament_type"))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault("tournament_name"))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault("tournament_ticker_name"))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault("tournament_shortname"))
	match.series = Logic.emptyOr(match.series, Variables.varDefault("tournament_series"))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault("tournament_icon"))
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault("tournament_tier"))
	match.liquipediatiertype = Logic.emptyOr(match.liquipediatiertype, Variables.varDefault("tournament_tier_type"))
	return match
end

function matchFunctions.getVodStuff(match)
	match.stream = match.stream or {}
	match.stream = Json.stringify({
		stream = Logic.emptyOr(match.stream.stream, Variables.varDefault("stream")),
		twitch = Logic.emptyOr(match.stream.twitch or match.twitch, Variables.varDefault("twitch")),
		twitch2 = Logic.emptyOr(match.stream.twitch2 or match.twitch2, Variables.varDefault("twitch2")),
		afreeca = Logic.emptyOr(match.stream.afreeca or match.afreeca, Variables.varDefault("afreeca")),
		afreecatv = Logic.emptyOr(match.stream.afreecatv or match.afreecatv, Variables.varDefault("afreecatv")),
		dailymotion = Logic.emptyOr(match.stream.dailymotion or match.dailymotion, Variables.varDefault("dailymotion")),
		douyu = Logic.emptyOr(match.stream.douyu or match.douyu, Variables.varDefault("douyu")),
		smashcast = Logic.emptyOr(match.stream.smashcast or match.smashcast, Variables.varDefault("smashcast")),
		youtube = Logic.emptyOr(match.stream.youtube or match.youtube, Variables.varDefault("youtube"))
	})
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault("vod"))

	match.lrthread = Logic.emptyOr(match.lrthread, Variables.varDefault("lrthread"))

	local links = {}
	if match.preview then links.preview = match.preview end
	if match.siegegg then links.siegegg = "https://siege.gg/matches/" .. match.siegegg end
	if match.opl then links.opl = "https://www.opleague.eu/match/" .. match.opl end
	if match.esl then links.esl = "https://play.eslgaming.com/match/" .. match.esl end
	if match.faceit then links.faceit = "https://www.faceit.com/en/rainbow_6/room/" .. match.faceit end
	if match.lpl then links.lpl = "https://letsplay.live/match/" .. match.lpl end
	match.links = Json.stringify(links)

	-- apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match["vodgame" .. index]
		if not Logic.isEmpty(vodgame) then
			local map = Logic.emptyOr(match["map" .. index], nil, {})
			if type(map) == "string" then
				map = Json.parse(map)
			end
			map.vod = map.vod or vodgame
			match["map" .. index] = map
		end
	end
	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = Json.stringify{
		matchsection = Variables.varDefault("matchsection"),
		lastgame = Variables.varDefault("last_game"),
		comment = match.comment,
		mapveto = Json.stringify(matchFunctions.getMapVeto(match)),
		mvp = Json.stringify(matchFunctions.getMVP(match)),
		isconverted = 0
	}
	return match
end

-- TODO: Needs improvment when it comes to upcoming games
function matchFunctions.getBestOf(match)
	local counter = 0
	for i = 1, MAX_NUM_MAPS do
		if match["map"..i] then
			counter = counter +1
		else
			break
		end
	end
	if counter > 0 then
		match.bestof = counter
	end
	return match
end

function matchFunctions.getMapVeto(match)
	if not match.mapveto then return nil end

	match.mapveto = Json.parse(match.mapveto)

	local vetotypes = mw.text.split(match.mapveto.types or '', ',')
	local deciders = mw.text.split(match.mapveto.decider or '', ',')
	local vetostart = match.mapveto.firstpick or ''
	local deciderIndex = 1

	local data = {}
	for index, vetoType in ipairs(vetotypes) do
		if vetoType:lower() == 'decider' then
			table.insert(data, {type = vetoType, decider = deciders[deciderIndex]})
			deciderIndex = deciderIndex + 1
		else
			table.insert(data, {type = vetoType, team1 = match.mapveto['t1map'..index], team2 = match.mapveto['t2map'..index]})
		end
	end
	if data[1] then
		data[1].vetostart = vetostart
	end
	return data
end

function matchFunctions.getMVP(match)
	if not match.mvp then return nil end
	local mvppoints = match.mvppoints or 1

	-- Split the input
	local players = mw.text.split(match.mvp, ',')

	-- Trim the input
	for index,player in pairs(players) do
		players[index] = mw.text.trim(player)
	end

	return {players=players, points=mvppoints}
end

function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args["opponent" .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			if type(opponent) == "string" then
				opponent = Json.parse(opponent)
			end

			--retrieve name and icon for teams from team templates
			if opponent.type == "team" and
				not Logic.isEmpty(opponent.template, args.date) then
					local name, icon, template = opponentFunctions.getTeamNameAndIcon(opponent.template, args.date)
					opponent.template = template or opponent.template
					opponent.name = opponent.name or name
					opponent.icon = opponent.icon or icon
			end

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = "S"
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == "team" and not Logic.isEmpty(opponent.name) then
				args = matchFunctions.getPlayers(args, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(args.finished) then
		local currentUnixTime = os.time(os.date("!*t"))
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', args.date))
		local threshold = args.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			args.finished = true
		end
	end

	-- apply placements and winner if finshed
	if Logic.readBool(args.finished) then
		local placement = 1
		for opponentIndex, opponent in Table.iter.spairs(opponents, p.placementSortFunction) do
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
		local player = match["opponent" .. opponentIndex .. "_p" .. playerIndex] or {}
		if type(player) == "string" then
			player = Json.parse(player)
		end
		player.name = player.name or Variables.varDefault(teamName .. "_p" .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. "_p" .. playerIndex .. "flag")
		player.displayname = player.displayname or Variables.varDefault(teamName .. "_p" .. playerIndex .. "dn")
		if not Table.isEmpty(player) then
			match["opponent" .. opponentIndex .. "_p" .. playerIndex] = player
		end
	end
	return match
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)
	map.extradata = Json.stringify{
		comment = map.comment,
		t1firstside = Json.stringify{map.t1firstside, ot = map.t1firstsideot},
		t1halfs = Json.stringify{atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = Json.stringify{atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
		t1bans = Json.stringify{map.t1ban1, map.t1ban2},
		t2bans = Json.stringify{map.t2ban1, map.t2ban2},
		pick = map.pick
	}
	return map
end

function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map["score" .. scoreIndex]
		if map["t".. scoreIndex .."atk"] then
			score =   (tonumber(map["t".. scoreIndex .."atk"]) or 0)
					+ (tonumber(map["t".. scoreIndex .."def"]) or 0)
					+ (tonumber(map["t".. scoreIndex .."otatk"]) or 0)
					+ (tonumber(map["t".. scoreIndex .."otdef"]) or 0)
		end
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
				obj.status = "S"
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end
	map = mapFunctions.getResultTypeAndWinner(indexedScores)

	return map
end

function mapFunctions.getResultTypeAndWinner(map, indexedScores)
	if map.finished == 'skip' or map.finished == 'np' then
		map.resulttype = 'np'
	elseif Logic.readBool(map.finished) then
		if p.placementCheckDraw(indexedScores) then
			map.winner = 0
			map.resulttype = 'draw'
		elseif p.placementCheckSpecialStatus(indexedScores) then
			map.winner = p.getDefaultWinner(indexedScores)
			map.resulttype = 'default'

			if p.placementCheckFF(indexedScores) then
				map.walkover = 'ff'
			elseif p.placementCheckDQ(indexedScores) then
				map.walkover = 'dq'
			elseif p.placementCheckWL(indexedScores) then
				map.walkover = 'l'
			end
		else
			--R6 only has exactly 2 opponents, neither more or less
			if #indexedScores ~= 2 then
				error('Unexpected number of opponents when calculating map winner')
			end
			if indexedScores[1] > indexedScores[2] then
				map.winner = 1
			else
				map.winner = 2
			end
		end
	end
	return map
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault("tournament_mode", "3v3"))
	map.type = Logic.emptyOr(map.type, Variables.varDefault("tournament_type"))
	map.tournament = Logic.emptyOr(map.tournament, Variables.varDefault("tournament_name"))
	map.tickername = Logic.emptyOr(map.tickername, Variables.varDefault("tournament_ticker_name"))
	map.shortname = Logic.emptyOr(map.shortname, Variables.varDefault("tournament_shortname"))
	map.series = Logic.emptyOr(map.series, Variables.varDefault("tournament_series"))
	map.icon = Logic.emptyOr(map.icon, Variables.varDefault("tournament_icon"))
	map.liquipediatier = Logic.emptyOr(map.liquipediatier, Variables.varDefault("tournament_tier"))
	map.liquipediatiertype = Logic.emptyOr(map.liquipediatiertype, Variables.varDefault("tournament_tier_type"))
	return map
end

--
-- opponent related functions
--
function opponentFunctions.getTeamNameAndIcon(template, date)
	local team, icon
	date = mw.getContentLanguage():formatDate('Y-m-d', date or '')
	template = (template or ''):lower():gsub('_', ' ')
	if template ~= '' and template ~= 'noteam' and
		mw.ext.TeamTemplate.teamexists(template) then

		local templateData = mw.ext.TeamTemplate.raw(template, date)
		icon = templateData.image
		if icon == '' then
			icon = templateData.legacyimage
		end
		team = templateData.page
		template = templateData.templatename or template
	end

	return team, icon, template
end

return p