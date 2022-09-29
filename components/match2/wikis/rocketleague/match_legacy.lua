---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local json = require("Module:Json")
local Logic = require("Module:Logic")
local String = require("Module:StringUtils")
local Table = require("Module:Table")
local Variables = require("Module:Variables")

function MatchLegacy.storeMatch(match2, options)
	local match = MatchLegacy._convertParameters(match2)

	if options.storeSmw then
		MatchLegacy.storeMatchSMW(match, match2)
	end

	if options.storeMatch1 then
		match.games = MatchLegacy.storeGames(match, match2)

		return mw.ext.LiquipediaDB.lpdb_match(
			"legacymatch_" .. match2.match2id,
			match
		)
	end
end

function MatchLegacy.storeMatchSMW(match, match2)
	local streams = match.stream or {}
	if type(streams) == "string" then streams = json.parse(streams) end
	local icon = Variables.varDefault("tournament_icon")
	local smwFormattedDate = mw.getContentLanguage():formatDate("c", match.date or "")
	local extradata = json.parseIfString(match.extradata) or {}
	mw.smw.subobject({
		"legacymatch_" .. match2.match2id,
		"has mode=" .. (match2.mode or ""),
		"is map number=1",
		"has team left=" .. (match.opponent1 or ""),
		"has team right=" .. (match.opponent2 or ""),
		"has teams=" .. (match.opponent1 or "") .. "," ..
			(match.opponent2 or ""), "+sep=,",
		"Has map date=" .. (smwFormattedDate or ""),
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
		"Has winner=" .. (match.winner or ""),
		"Is featured match=" .. (extradata.isfeatured and "true" or "false"),
		"Has calendar icon=" .. (not Logic.isEmpty(icon) and "File:" .. icon or ""),
		"Has calendar description=" .. " - " .. Logic.emptyOr(match.opponent1, "TBD")
			.. " vs " .. Logic.emptyOr(match.opponent2, "TBD") .. " on "
			.. Logic.emptyOr(match.date, "TBD")
	})
end

function MatchLegacy.storeGames(match, match2)
	local games = ""
	for gameIndex, game in ipairs(match2.match2games or {}) do
		game = Table.deepCopy(game)
		game.opponent1 = match.opponent1
		game.opponent2 = match.opponent2
		game.opponent1flag = match.opponent1flag
		game.opponent2flag = match.opponent2flag
		game.date = match.date
		local scores = game.scores or {}
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

function MatchLegacy._convertParameters(match2)
	local match = Table.deepCopy(match2)
	for key, _ in pairs(match) do
		if String.startsWith(key, "match2") then
			match[key] = nil
		end
	end

	match.staticid = match2.match2id

	local opponent1 = match2.match2opponents[1] or {}
	local opponent1match2players = opponent1.match2players or {}
	if opponent1.type == "team" then
		match.opponent1 = opponent1.name
		match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0
			and opponent1.score or 0
		local opponent1players = {}
		for i = 1,10 do
			local player = opponent1match2players[i] or {}
			opponent1players["p" .. i] = player.name or ""
			opponent1players["p" .. i .. "flag"] = player.flag or ""
		end
		match.opponent1players = json.stringify(opponent1players)
	elseif opponent1.type == "solo" then
		local player = opponent1match2players[1] or {}
		match.opponent1 = player.name
		match.opponent1score = (tonumber(opponent1.score or 0) or 0) >= 0
			and opponent1.score or 0
		match.opponent1flag = player.flag
	end

	local opponent2 = match2.match2opponents[2] or {}
	local opponent2match2players = opponent2.match2players or {}
	if opponent2.type == "team" then
		match.opponent2 = opponent2.name
		match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0
			and opponent2.score or 0
		local opponent2players = {}
		for i = 1,10 do
			local player = opponent2match2players[i] or {}
			opponent2players["p" .. i] = player.name or ""
			opponent2players["p" .. i .. "flag"] = player.flag or ""
		end
		match.opponent2players = json.stringify(opponent2players)
	elseif opponent2.type == "solo" then
		local player = opponent2match2players[1] or {}
		match.opponent2 = player.name
		match.opponent2score = (tonumber(opponent2.score or 0) or 0) >= 0
			and opponent2.score or 0
		match.opponent2flag = player.flag
	end
	if match2.walkover then
		match.resulttype = match2.walkover
		match.walkover = nil
	end

	return match
end

return MatchLegacy
