---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local FeatureFlag = require('Module:FeatureFlag')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local legacy = Lua.moduleExists('Module:Match/Legacy') and require('Module:Match/Legacy') or nil

local storeInLpdb

local Match = {}

function Match.storeFromArgs(frame)
	Match.store(Arguments.getArgs(frame))
end

function Match.toEncodedJson(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local Match_ = Lua.import('Module:Match', {requireDevIfEnabled = true})
		return Match_.withPerformanceSetup(function()
			return Match_._toEncodedJson(args)
		end)
	end)
end

function Match._toEncodedJson(matchArgs)
	-- handle tbd and literals for opponents
	for opponentIndex = 1, matchArgs[1] or 2 do
		local opponent = matchArgs['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			matchArgs['opponent' .. opponentIndex] = {
				['type'] = 'literal', template = 'tbd', name = matchArgs['opponent' .. opponentIndex .. 'literal']
			}
		end
	end

	-- handle literals for qualifiers
	matchArgs.bracketdata = {
		qualwinLiteral = matchArgs.qualwinliteral,
		qualloseLiteral = matchArgs.qualloseliteral,
	}

	for key, map in Table.iter.pairsByPrefix(matchArgs, 'map') do
		matchArgs[key] = Json.parseIfString(map)
	end
	for key, opponent in Table.iter.pairsByPrefix(matchArgs, 'opponent') do
		matchArgs[key] = Json.parseIfString(opponent)
	end

	return Json.stringify(matchArgs)
end

local function stringifyNonEmpty(tbl)
	return not Table.isEmpty(table)
		and Json.stringify(tbl)
		or nil
end

function Match.store(args, shouldStoreInLpdb)
	storeInLpdb = shouldStoreInLpdb
	local matchid = args.matchid or -1
	local bracketid = args.bracketid or -1
	local staticid = bracketid .. '_' .. matchid

	-- save opponents (and players) to lpdb
	local opponents, rawOpponents = Match._storeOpponents(args, staticid, nil)

	-- save games to lpdb
	local games, rawGames = Match._storeGames(args, staticid)

	-- build parameters
	local parameters = Match._buildParameters(args)
	parameters.match2id = staticid
	parameters.match2bracketid = bracketid
	parameters.match2opponents = opponents
	parameters.match2games = games
	parameters.extradata = stringifyNonEmpty(parameters.extradata)
	parameters.links = stringifyNonEmpty(parameters.links)
	parameters.match2bracketdata = stringifyNonEmpty(parameters.match2bracketdata)
	parameters.stream = stringifyNonEmpty(parameters.stream)

	-- save legacy match to lpdb
	if args.disableLegacyStorage ~= true and legacy ~= nil and storeInLpdb then
		Match._storeLegacy(parameters, rawOpponents, rawGames)
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

function Match.templateFromMatchID(frame)
	local args = Arguments.getArgs(frame)
	local matchid = args[1] or 'match id is empty'
	local out = matchid:gsub('0*([1-9])', '%1'):gsub('%-', '')
	return out
end

function Match._storeLegacy(parameters, rawOpponents, rawGames)
	local rawMatch = Table.deepCopy(parameters)
	rawMatch.match2opponents = rawOpponents
	rawMatch.match2games = rawGames
	legacy.storeMatch(rawMatch)
end

function Match._storePlayers(args, staticid, opponentIndex)
	local players = ''
	local rawPlayers = {}
	for playerIndex = 1, 100 do
		-- read player
		local player = args['opponent' .. opponentIndex .. '_p' .. playerIndex]
		if player == nil then break end

		player.extradata = stringifyNonEmpty(player.extradata)

		table.insert(rawPlayers, player)

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2player(
				staticid .. '_m2o_' .. opponentIndex .. '_m2p_' .. playerIndex, player
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

function Match._storeOpponents(args, staticid, opponentPlayers)
	local opponents = ''
	local rawOpponents = {}

	for opponentIndex = 1, 100 do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if opponent == nil then	break end

		opponent.extradata = stringifyNonEmpty(opponent.extradata)

		-- get nested players if exist
		if not Logic.isEmpty(opponent.match2players) then
			local players = opponent.match2players or {}
			for playerIndex, player in ipairs(players) do
				args['opponent' .. opponentIndex .. '_p' .. playerIndex] = player
			end
		end

		-- store players to lpdb
		local players, rawPlayers = Match._storePlayers(args, staticid, opponentIndex, storeInLpdb)

		-- set parameters
		opponent.match2players = players

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2opponent(staticid .. '_m2o_' .. opponentIndex, opponent)
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

function Match._storeGames(args, staticid)
	local games = ''
	local rawGames = {}

	for gameIndex = 1, 100 do
		-- read game
		local game = args['game' .. gameIndex] or args['map' .. gameIndex]
		if game == nil then
			break
		end

		-- stringify Json stuff

		game.extradata = stringifyNonEmpty(game.extradata)
		game.participants = stringifyNonEmpty(game.participants)
		game.scores = stringifyNonEmpty(game.scores)

		table.insert(rawGames, game)

		-- lpdb save operation
		local res
		if storeInLpdb then
			res = mw.ext.LiquipediaDB.lpdb_match2game(staticid .. '_m2g_' .. gameIndex, game)
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

function Match._buildParameters(args)
	local parameters = {
		bestof = args.bestof,
		date = args.date,
		dateexact = Logic.readBool(args.dateexact) and 1 or 0,
		extradata = args.extradata,
		finished = Logic.readBool(args.finished) and 1 or 0,
		game = args.game,
		icon = args.icon,
		icondark = args.icondark,
		links = args.links,
		liquipediatier = args.liquipediatier,
		liquipediatiertype = args.liquipediatiertype,
		lrthread = args.lrthread,
		match2bracketdata = args.bracketdata or args.match2bracketdata,
		mode = args.mode,
		parent = args.parent,
		parentname = args.parentname,
		patch = args.patch,
		publishertier = args.publishertier,
		resulttype = args.resulttype,
		series = args.series,
		shortname = args.shortname,
		status = args.status,
		stream = args.stream,
		tickername = args.tickername,
		tournament = args.tournament,
		type = args.type,
		vod = args.vod,
		walkover = args.walkover,
		winner = args.winner,
	}
	return parameters
end

function Match.withPerformanceSetup(f)
	if FeatureFlag.get('perf') then
		local matchGroupConfig = Lua.loadDataIfExists('Module:MatchGroup/Config')
		local perfConfig = Table.getByPathOrNil(matchGroupConfig, {'subobjectPerf'}) or {}
		return require('Module:Performance/Util').withSetup(perfConfig, f)
	else
		return f()
	end
end

return Match
