local p = {}

local getArgs = require("Module:Arguments").getArgs
local json = require("Module:Json")
local utils = require("Module:LuaUtils")
local args

local legacy = utils.lua.moduleExists("Module:Match/Legacy") and require("Module:Match/Legacy") or nil
local config = utils.lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

function p.storeFromArgs(frame)
	p.store(getArgs(frame))
end
function p.toEncodedJson(frame)
  	args = getArgs(frame)
  
  	-- handle tbd and literals for opponents
  	for opponentIndex = 1, args["1"] or 2 do
		opponent = args["opponent" .. opponentIndex]
		if utils.misc.isEmpty(opponent) then
	  		args["opponent" .. opponentIndex] = { ["type"] = "literal", template = "tbd", name = args["opponent" .. opponentIndex .. "literal"] }
	  	end
	end
  
   	-- handle literals for qualifiers
  	local bracketdata = json.parse(args.bracketdata or "{}")
  	bracketdata.qualwinLiteral = args.qualwinliteral
  	bracketdata.qualloseLiteral = args.qualloseliteral
  	args.bracketdata = json.stringify(bracketdata)
  	
  	-- parse maps
  	local lastMap
  	local lastMapIndex
  	for mapIndex = 1, MAX_NUM_MAPS do
		map = args["map" .. mapIndex]
		if type(map) == "string" then
	  		map = json.parse(map)
	  		lastMap = map
	  		lastMapIndex = mapIndex
	  		args["map" .. mapIndex] = map
		else
	  		break
	  	end
	end
  
	return json.stringify(args)
end

function p.store(args)
	local matchid = args["matchid"] or -1
	local bracketid = args["bracketid"] or -1
	local staticid = bracketid .. "_" .. matchid

	-- save opponents (and players) to lpdb
	local opponents, rawOpponents = storeOpponents(args, staticid)

	-- save games to lpdb
	local games, rawGames = storeGames(args, staticid)
  
  	-- build parameters
  	local parameters = buildParameters(args)
  	parameters.match2id = staticid
	parameters.match2bracketid = bracketid
	parameters.match2opponents = opponents
	parameters.match2games = games
	
	mw.log(opponents)
  
  	-- save legacy match to lpdb
  	if args.disableLegacyStorage ~= true and legacy ~= nil then
		storeLegacy(parameters, rawOpponents, rawGames)
	end

	-- save match to lpdb
	local res =
		mw.ext.LiquipediaDB.lpdb_match2(
		staticid,
		parameters
	)
  	
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

function storeLegacy(parameters, rawOpponents, rawGames)
	local rawMatch = utils.table.shallowCopy(parameters)
	rawMatch.match2opponents = rawOpponents
	rawMatch.match2games = rawGames
	legacy.storeMatch(rawMatch)
end

function storePlayers(args, staticid, opponentIndex)
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
	  local res =
	  mw.ext.LiquipediaDB.lpdb_match2player(staticid .. "_m2o_" .. opponentIndex .. "_m2p_" .. playerIndex, player)

	  -- append player to string to allow setting the match2opponentid later
	  players = players .. res
	end
	return players, rawPlayers
end

function storeOpponents(args, staticid, opponentPlayers)
	local opponents = ""
  	local rawOpponents = {}
  
	for opponentIndex = 1, 100 do
		-- read opponent
		opponent = args["opponent" .. opponentIndex]
		if opponent == nil then	break end
		if type(opponent) == "string" then
			opponent = json.parse(opponent)
	  	end
	
		-- get nested players if exist
		if not utils.misc.isEmpty(opponent.match2players) then
			local players = opponent.match2players or {}
			if type(players) == "string" then
				players = json.parse(players)
			end
	  		for playerIndex, player in ipairs(players) do
				args["opponent" .. opponentIndex .. "_p" .. playerIndex] = player
			end
	  	end
	
		-- store players to lpdb
	  	local players, rawPlayers = storePlayers(args, staticid, opponentIndex)

		-- set parameters
		opponent.match2players = players
		
		-- lpdb save operation
		local res = mw.ext.LiquipediaDB.lpdb_match2opponent(staticid .. "_m2o_" .. opponentIndex, opponent)
		
		-- recover raw players
		opponent.match2players = rawPlayers
		table.insert(rawOpponents, opponent)		

		-- append opponents to string to allow setting the match2opponentid later
		opponents = opponents .. res
	end
	return opponents, rawOpponents
end

function storeGames(args, staticid)
	local games = ""
  	local rawGames = {}
  	
	for gameIndex = 1, 100 do
		-- read game
		game = args["game" .. gameIndex] or args["map" .. gameIndex]
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
		local res = mw.ext.LiquipediaDB.lpdb_match2game(staticid .. "_m2g_" .. gameIndex, game)

		-- append games to string to allow setting the match2id later
		games = games .. res
	end
	return games, rawGames
end

function buildParameters(args)
	local parameters = {
		winner = args["winner"],
		walkover = args["walkover"],
		resulttype = args["resulttype"],
		finished = utils.misc.readBool(args["finished"]) and 1 or 0,
		mode = args["mode"],
		type = args["type"],
		game = args["game"],
		date = args["date"],
		dateexact = utils.misc.readBool(args["dateexact"]) and 1 or 0,
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
