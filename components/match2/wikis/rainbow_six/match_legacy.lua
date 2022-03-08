---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local p = {}

local json = require("Module:Json")
local Logic = require("Module:Logic")
local Lua = require("Module:Lua")
local String = require("Module:StringUtils")
local Table = require("Module:Table")
local Variables = require("Module:Variables")

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})

function p.storeMatch(match2)
	local match = p.convertParameters(match2)

	match.games = p.storeGames(match, match2)

	p.storeMatchSMW(match, match2)

	return mw.ext.LiquipediaDB.lpdb_match(
		"legacymatch_" .. match2.match2id,
		match
	)
end

function p.storeMatchSMW(match, match2)
	local streams = json.parseIfString(match.stream or {})
	local links = json.parseIfString(match.links or {})
	local icon = Variables.varDefault("tournament_icon")
	mw.smw.subobject({
		"legacymatch_" .. match2.match2id,
		"is map number=1",
		"has team left=" .. (match.opponent1 or ""),
		"has team right=" .. (match.opponent2 or ""),
		"Has map date=" .. (match.date or ""),
		"Has tournament=" .. mw.title.getCurrentTitle().prefixedText,
		"Has tournament tier=" .. (match.liquipediatier or ""),
		"Has match stream=" .. (streams.stream or ""),
		"Has match twitch=" .. (streams.twitch or ""),
		"Has match twitch2=" .. (streams.twitch2 or ""),
		"Has match youtube=" .. (streams.youtube or ""),
		"Has match vod=" .. (match.vod or ""),
		"Has siegegg=" .. (links.siegegg or ""),
		"Has r6esports=" .. (links.r6esports or ""),
		"Has tournament name=" .. Logic.emptyOr(match.tickername, match.name, ""),
		"Has tournament icon=" .. (icon or ""),
		"Has winner=" .. (match.winner or ""),
		"Has team left score=" .. (match.opponent1score or "0"),
		"Has team right score=" .. (match.opponent2score or "0"),
		"Has exact time=" .. (Logic.readBool(match.dateexact) and "true" or "false"),
		"Is finished=" .. (Logic.readBool(match.finished) and "true" or "false"),
	 })
end

function p.storeGames(match, match2)
	local games = ""
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local game = Table.deepCopy(game2)
		-- Extradata
		local extradata = json.parseIfString(game2.extradata)
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		if extradata.t1bans and extradata.t2bans then
			game.extradata.opponent1bans = table.concat(json.parseIfString(extradata.t1bans), ", ")
			game.extradata.opponent2bans = table.concat(json.parseIfString(extradata.t2bans), ", ")
		end
		if extradata.t1firstside and extradata.t1halfs and extradata.t2halfs then
			extradata.t1firstside = json.parseIfString(extradata.t1firstside)
			extradata.t1halfs = json.parseIfString(extradata.t1halfs)
			extradata.t2halfs = json.parseIfString(extradata.t2halfs)
			local team1 = {}
			local team2 = {}
			if extradata.t1firstside.rt == "atk" then
				team1 = {"atk", extradata.t1halfs.atk or 0, extradata.t1halfs.def or 0}
				team2 = {"def", extradata.t2halfs.atk or 0, extradata.t2halfs.def or 0}
			elseif extradata.t1firstside.rt == "def" then
				team2 = {"atk", extradata.t2halfs.atk or 0, extradata.t2halfs.def or 0}
				team1 = {"def", extradata.t1halfs.atk or 0, extradata.t1halfs.def or 0}
			end
			if extradata.t1firstside.ot == "atk" then
				table.insert(team1, "atk")
				table.insert(team1, extradata.t1halfs.otatk or 0)
				table.insert(team1, extradata.t1halfs.otdef or 0)
				table.insert(team2, "def")
				table.insert(team2, extradata.t2halfs.otatk or 0)
				table.insert(team2, extradata.t2halfs.otdef or 0)
			elseif extradata.t1firstside.ot == "def" then
				table.insert(team2, "atk")
				table.insert(team2, extradata.t2halfs.otatk or 0)
				table.insert(team2, extradata.t2halfs.otdef or 0)
				table.insert(team1, "def")
				table.insert(team1, extradata.t1halfs.otatk or 0)
				table.insert(team1, extradata.t1halfs.otdef or 0)
			end
			game.extradata.opponent1scores = table.concat(team1, ", ")
			game.extradata.opponent2scores = table.concat(team2, ", ")
		end
		game.extradata = mw.ext.LiquipediaDB.lpdb_create_json(game.extradata)
		-- Other stuff
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = game2.scores or {}
		if type(scores) == "string" then
			scores = json.parse(scores)
		end
		game.opponent1score = scores[1] or 0
		game.opponent2score = scores[2] or 0
		local res = mw.ext.LiquipediaDB.lpdb_game(
			"legacygame_" .. match2.match2id .. gameIndex,
			game
		)
		games = games .. res
	end
	return games
end

function p.convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, "match2") then
			match[key] = nil
		end
	end

	if match.walkover == "ff" or match.walkover == "dq" then
		match.walkover = match.winner
	elseif match.walkover == "l" then
		match.walkover = nil
	end

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = json.parseIfString(match2.extradata)

	local mvp = json.parseIfString(extradata.mvp)
	if mvp and mvp.players then
		match.extradata.mvp = table.concat(mvp.players, ",")
		match.extradata.mvp = match.extradata.mvp .. ";" .. mvp.points
	end

	match.extradata.matchsection = extradata.matchsection
	match.extradata.bestofx = tostring(match2.bestof)
	local bracketData = json.parseIfString(match2.match2bracketdata)
	if type(bracketData) == "table" and bracketData.type == "bracket" then
		local headerName
		if bracketData.header then
			headerName = (DisplayHelper.expandHeader(bracketData.header) or {})[1]
		end
		if String.isEmpty(headerName) then
			headerName = Variables.varDefault("match_legacy_header_name")
		end
		if String.isNotEmpty(headerName) then
			match.header = headerName
			Variables.varDefine("match_legacy_header_name", headerName)
		end
	end

	local veto = json.parseIfString(extradata.mapveto)
	if veto then
		for k, round in ipairs(veto) do
			if k == 1 then
				match.extradata.firstban = round.vetostart
			end
			if not round.type then break end
			if round.team1 or round.decider then
				match.extradata["opponent1mapban"..k] = (round.team1 or round.decider) .. "," .. round.type
			end
			if round.team2 then
				match.extradata["opponent2mapban"..k] = round.team2 .. "," .. round.type
			end
		end
	end

	match.extradata = mw.ext.LiquipediaDB.lpdb_create_json(match.extradata)

	-- Handle Opponents
	local handleOpponent = function (index)
		local prefix = "opponent"..index
		local opponent = match2.match2opponents[index] or {}
		local opponentmatch2players = opponent.match2players or {}
		if opponent.type == "team" then
			match[prefix] = mw.ext.TeamTemplate.teampage(opponent.template)
			match[prefix.."score"] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			local opponentplayers = {}
			for i = 1,10 do
				local player = opponentmatch2players[i] or {}
				opponentplayers["p" .. i] = player.name or ""
				opponentplayers["p" .. i .. "flag"] = player.flag or ""
				opponentplayers["p" .. i .. "dn"] = player.displayname or ""
			end
			match[prefix.."players"] = mw.ext.LiquipediaDB.lpdb_create_json(opponentplayers)
		elseif opponent.type == "solo" then
			local player = opponentmatch2players[1] or {}
			match[prefix] = player.name
			match[prefix.."score"] = (tonumber(opponent.score) or 0) > 0 and opponent.score or 0
			match[prefix.."flag"] = player.flag
		elseif opponent.type == "literal" then
			match[prefix] = 'TBD'
		end
	end

	handleOpponent(1)
	handleOpponent(2)

	return match
end

return p
