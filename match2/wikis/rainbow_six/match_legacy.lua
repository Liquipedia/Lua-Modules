local p = {}

local json = require("Module:Json")
local Logic = require("Module:Logic")
local String = require("Module:StringUtils")
local Table = require("Module:Table")
local Variables = require("Module:Variables")

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
	local streams = match.stream or {}
	if type(streams) == "string" then streams = json.parse(streams) end
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
		"Has tournament name=" .. Logic.emptyOr(match.tickername, match.name, ""),
		"Has tournament icon=" .. (icon or ""),
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
		local extradata = json.parse(game2.extradata)
		game.extradata = {}
		game.extradata.gamenumber = gameIndex
		if extradata.t1bans and extradata.t2bans then
			game.extradata.opponent1bans = table.concat(json.parse(extradata.t1bans), ", ")
			game.extradata.opponent2bans = table.concat(json.parse(extradata.t2bans), ", ")
		end
		if extradata.t1firstside and extradata.t1halfs and extradata.t2halfs then
			extradata.t1firstside = json.parse(extradata.t1firstside)
			extradata.t1halfs = json.parse(extradata.t1halfs)
			extradata.t2halfs = json.parse(extradata.t2halfs)
			local team1 = {}
			local team2 = {}
			if extradata.t1firstside[1] == "atk" then
				team1 = {"atk", extradata.t1halfs.atk, extradata.t1halfs.def}
				team2 = {"def", extradata.t2halfs.def, extradata.t2halfs.atk}
			elseif extradata.t1firstside[1] == "def" then
				team2 = {"atk", extradata.t2halfs.atk, extradata.t2halfs.def}
				team1 = {"def", extradata.t1halfs.def, extradata.t1halfs.atk}
			end
			if extradata.t1firstside.ot == "atk" then
				table.insert(team1, "atk")
				table.insert(team1, extradata.t1halfs.otatk)
				table.insert(team1, extradata.t1halfs.otdef)
				table.insert(team2, "def")
				table.insert(team2, extradata.t2halfs.otatk)
				table.insert(team2, extradata.t2halfs.otdef)
			elseif extradata.t1firstside.ot == "def" then
				table.insert(team2, "atk")
				table.insert(team2, extradata.t2halfs.otatk)
				table.insert(team2, extradata.t2halfs.otdef)
				table.insert(team1, "def")
				table.insert(team1, extradata.t1halfs.otatk)
				table.insert(team1, extradata.t1halfs.otdef)
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

	match.staticid = match2.match2id

	-- Handle extradata fields
	match.extradata = {}
	local extradata = json.parse(match2.extradata)

	local mvp = json.parse(extradata.mvp)
	if mvp and mvp.players then
		match.extradata.mvp = table.concat(mvp.players, ",")
		match.extradata.mvp = match.extradata.mvp .. ";" .. mvp.points
	end

	match.extradata.bestofx = match2.bestof

	local veto = json.parse(extradata.mapveto)
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
			match[prefix] = opponent.name
			match[prefix.."score"] = tonumber(opponent.score or 0) >= 0 and opponent.score or 0
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
			match[prefix.."score"] = tonumber(opponent.score or 0) >= 0 and opponent.score or 0
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