local p = {}

local getArgs = require("Module:Arguments").getArgs
local json = require("Module:Json")
local Logic = require("Module:Logic")
local Lua = require("Module:Lua")
local Table = require("Module:Table")
local globalArgs
local storeInLpdb

local legacy = Lua.moduleExists("Module:Match/Legacy") and require("Module:Match/Legacy") or nil
local config = Lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

function p.storeFromArgs(frame)
	p.store(getArgs(frame))
end

function p.toEncodedJson(frame)
	globalArgs = getArgs(frame)

	-- handle tbd and literals for opponents
	for opponentIndex = 1, globalArgs["1"] or 2 do
		local opponent = globalArgs["opponent" .. opponentIndex]
		if Logic.isEmpty(opponent) then
			globalArgs["opponent" .. opponentIndex] = {
				["type"] = "literal", template = "tbd", name = globalArgs["opponent" .. opponentIndex .. "literal"]
			}
		end
	end

	-- handle literals for qualifiers
	local bracketdata = json.parse(globalArgs.bracketdata or "{}")
	bracketdata.qualwinLiteral = globalArgs.qualwinliteral
	bracketdata.qualloseLiteral = globalArgs.qualloseliteral
	globalArgs.bracketdata = json.stringify(bracketdata)

	-- parse maps
	for mapIndex = 1, MAX_NUM_MAPS do
		local map = globalArgs["map" .. mapIndex]
		if type(map) == "string" then
			map = json.parse(map)
			globalArgs["map" .. mapIndex] = map
		else
			break
		end
	end

	return json.stringify(globalArgs)
end

function p.store(args, shouldStoreInLpdb)
	storeInLpdb = shouldStoreInLpdb
	local matchid = args["matchid"] or -1
	local bracketid = args["bracketid"] or -1
	local staticid = bracketid .. "_" .. matchid

	-- save opponents (and players) to lpdb
	local opponents, rawOpponents = p._storeOpponents(args, staticid, nil, storeInLPDB)

	-- save games to lpdb
	local games, rawGames = p._storeGames(args, staticid, storeInLPDB)

	-- build parameters
	local parameters = p._buildParameters(args)
	parameters.match2id = staticid
	parameters.match2bracketid = bracketid
	parameters.match2opponents = opponents
	parameters.match2games = games

	mw.log(opponents)

	-- save legacy match to lpdb
	if args.disableLegacyStorage ~= true and legacy ~= nil and storeInLpdb then
		p._storeLegacy(parameters, rawOpponents, rawGames)
	end

	-- save match to lpdb
	if storeInLpdb then
		mw.ext.LiquipediaDB.lpdb_match2(
			staticid,
			parameters
		)
	end

	-- return reconstructed json for previews
	parameters.match2opponents = rawOpponents
	parameters.match2games = rawGames
	return parameters
end

function p.templateFromMatchID(frame)
	local args = getArgs(frame)
	local matchid = args["1"] or "match id is empty"
	local out = matchid:gsub("0*([1-9])", "%1"):gsub("%-", "")
	return out
end

function p._storeLegacy(parameters, rawOpponents, rawGames)
	local rawMatch = Table.deepCopy(parameters)
	rawMatch.match2opponents = rawOpponents
	rawMatch.match2games = rawGames
	legacy.storeMatch(rawMatch)
end

function p._storePlayers(args, staticid, opponentIndex, storeInLPDB)
	local players = ""
	local rawPlayers = {}
	for playerIndex = 1, 100 do
		-- read player
		local player = args["opponent" .. opponentIndex .. "_p" .. playerIndex]
		if player == nil then break end
		if type(player) == "string" then
			player = json.parse(player)
		end

		table.insert(rawPlayers, player)

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2player(
				staticid .. "_m2o_" .. opponentIndex .. "_m2p_" .. playerIndex, player
			)
		else
			-- the storage into Lpdb returned the playerIndex into res
			-- so to be able to use res 4 lines further down we set it here accordingly
			res = playerIndex
		end

		-- append player to string to allow setting the match2opponentid later
		players = players .. res
	end
	return players, rawPlayers
end

function p._storeOpponents(args, staticid, opponentPlayers, storeInLPDB)
	local opponents = ""
	local rawOpponents = {}

	for opponentIndex = 1, 100 do
		-- read opponent
		local opponent = args["opponent" .. opponentIndex]
		if opponent == nil then	break end
		if type(opponent) == "string" then
			opponent = json.parse(opponent)
		end

		-- get nested players if exist
		if not Logic.isEmpty(opponent.match2players) then
			local players = opponent.match2players or {}
			if type(players) == "string" then
				players = json.parse(players)
			end
			for playerIndex, player in ipairs(players) do
				args["opponent" .. opponentIndex .. "_p" .. playerIndex] = player
			end
		end

		-- store players to lpdb
		local players, rawPlayers = p._storePlayers(args, staticid, opponentIndex, storeInLpdb)

		-- set parameters
		opponent.match2players = players

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2opponent(staticid .. "_m2o_" .. opponentIndex, opponent)
		else
			-- the storage into Lpdb returned the opponentIndex into res
			-- so to be able to use res 4 lines further down we set it here accordingly
			res = opponentIndex
		end

		-- recover raw players
		opponent.match2players = rawPlayers
		table.insert(rawOpponents, opponent)

		-- append opponents to string to allow setting the match2opponentid later
		opponents = opponents .. res
	end
	return opponents, rawOpponents
end

function p._storeGames(args, staticid, storeInLPDB)
	local games = ""
	local rawGames = {}

	for gameIndex = 1, 100 do
		-- read game
		local game = args["game" .. gameIndex] or args["map" .. gameIndex]
		if game == nil then
			break
		end
		if type(game) == "string" then
			game = json.parse(game)
		end

		-- stringify json stuff
		if game.scores ~= nil and type(game.scores) == "table" then
			game.scores = json.stringify(game.scores)
		end
		if game.participants ~= nil and type(game.participants) == "table" then
			game.participants = json.stringify(game.participants)
		end

		table.insert(rawGames, game)

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2game(staticid .. "_m2g_" .. gameIndex, game)
		else
			-- the storage into Lpdb returned the gameIndex into res
			-- so to be able to use res 4 lines further down we set it here accordingly
			res = gameIndex
		end

		-- append games to string to allow setting the match2id later
		games = games .. res
	end
	return games, rawGames
end

function p._buildParameters(args)
	local parameters = {
		winner = args["winner"],
		walkover = args["walkover"],
		resulttype = args["resulttype"],
		finished = Logic.readBool(args["finished"]) and 1 or 0,
		mode = args["mode"],
		type = args["type"],
		game = args["game"],
		date = args["date"],
		dateexact = Logic.readBool(args["dateexact"]) and 1 or 0,
		stream = args["stream"],
		bestof = args["bestof"],
		links = args["links"],
		lrthread = args["lrthread"],
		vod = args["vod"],
		tournament = args["tournament"],
		parent = args["parent"],
		parentname = args["parentname"],
		tickername = args["tickername"],
		shortname = args["shortname"],
		series = args["series"],
		icon = args["icon"],
		liquipediatier = args["liquipediatier"],
		publishertier = args["publishertier"],
		status = args["status"],
		patch = args["patch"],
		extradata = args["extradata"],
		match2bracketdata = args["bracketdata"] or args["match2bracketdata"]
	}
	return parameters
end

return p
