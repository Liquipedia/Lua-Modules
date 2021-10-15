---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L', 'D' }
local ALLOWED_VETOES = { 'decider', 'pick', 'ban', 'defaultban' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_VODGAMES = 9
local MAX_NUM_MAPS = 9
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local _EPOCH_TIME = '1970-01-01 00:00:00'

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(_, match)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.removeUnsetMaps(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(
		match,
		matchFunctions.readDate(match)
	)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(_, map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)

	return map
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processOpponent(_, opponent)
	-- check for empty team and convert to literal
	if type(opponent) == 'table' and opponent.type == 'team' and Logic.isEmpty(opponent.template) then
		opponent.name = ''
		opponent.type = 'literal'
	end

	-- check for lazy bye's and convert them to literals
	if type(opponent) == 'table' and string.lower(opponent.template or '') == 'bye' then
			opponent.name = 'BYE'
			opponent.type = 'literal'
	end

	return opponent
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(_, player)
	return player
end

--
--
-- function to check for draws
function CustomMatchGroupInput.placementCheckDraw(table)
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

-- Set the field 'placement' for the two participants in the opponenets list.
-- Set the placementWinner field to the winner, and placementLoser to the other team
-- Special cases:
-- If Winner = 0, that means draw, and placementLoser isn't used. Both teams will get placementWinner
-- If Winner = -1, that mean no team won, and placementWinner isn't used. Both teams will gt placementLoser
function CustomMatchGroupInput.setPlacement(opponents, winner, placementWinner, placementLoser)
	if opponents and #opponents == 2 then
		local loserIdx
		local winnerIdx
		if winner == 1 then
			winnerIdx = 1
			loserIdx = 2
		elseif winner == 2 then
			winnerIdx = 2
			loserIdx = 1
		elseif winner == 0 then
			-- Draw; idx of winner/loser doesn't matter
			-- since loser and winner gets the same placement
			placementLoser = placementWinner
			winnerIdx = 1
			loserIdx = 2
		elseif winner == -1 then
			-- No Winner (both loses). For example if both teams DQ.
			-- idx's doesn't matter
			placementWinner = placementLoser
			winnerIdx = 1
			loserIdx = 2
		else
			error('setPlacement: Unexpected winner')
			return opponents
		end
		opponents[winnerIdx].placement = placementWinner
		opponents[loserIdx].placement = placementLoser
	end
	return opponents
end

function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if data.finished == 'skip' or data.finished == 'np' or data.finished == 'cancelled' or data.finished == 'canceled' then
		data.resulttype = 'np'
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if CustomMatchGroupInput.placementCheckDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = CustomMatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = 'default'
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		else
			--R6 only has exactly 2 opponents, neither more or less
			if #indexedScores ~= 2 then
				error('Unexpected number of opponents when calculating map winner')
			end
			if indexedScores[1].score > indexedScores[2].score then
				data.winner = 1
			else
				data.winner = 2
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		end
	end
	return data, indexedScores
end


-- Check if any team has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(table)
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
function matchFunctions.getBestOf(match)
	local mapCount = 0
	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			mapCount = mapCount + 1
		else
			break
		end
	end
	match.bestof = mapCount
	return match
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored in lpdb, nor displayed
-- The discardMap function will check if a map should be removed
-- Remove all maps that should be removed.
function matchFunctions.removeUnsetMaps(match)
	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			if mapFunctions.discardMap(match['map'..i]) then
				match['map'..i] = nil
			end
		else
			break
		end
	end
	return match
end

-- Calculate the match scores based on the map results.
-- If it's a Best of 1, we'll take the exact score of that map
-- If it's not a Best of 1, we should count the map wins
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	-- For best of 1, display the results of the single map
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	local newScores = {}
	local foundScores = false
	if match.bestof == 1 then
		if match.map1 then
			newScores = match.map1.scores
			foundScores = true
		end
	else -- For best of >1, disply the map wins
		for i = 1, MAX_NUM_MAPS do
			if match['map'..i] then
				local winner = tonumber(match['map'..i].winner)
				foundScores = true
				-- Only two opponents in R6
				if winner and winner > 0 and winner <= 2 then
					newScores[winner] = (newScores[winner] or 0) + 1
				end
			else
				break
			end
		end
	end
	if not opponent1.score and foundScores then
		opponent1.score = newScores[1] or 0
	end
	if not opponent2.score and foundScores then
		opponent2.score = newScores[2] or 0
	end
	match.opponent1 = opponent1
	match.opponent2 = opponent2
	return match
end

function matchFunctions.readDate(matchArgs)
	if matchArgs.date then
		local dateProps = MatchGroupInput.readDate(matchArgs.date)
		dateProps.hasDate = true
		return dateProps
	else
		return {
			date = mw.getContentLanguage():formatDate('c', _EPOCH_TIME),
			dateexact = false,
		}
	end
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.type = Logic.emptyOr(match.type, Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_ticker_name'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
	match.icondark = Logic.emptyOr(match.iconDark, Variables.varDefault('tournament_icon_dark'))
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault('tournament_tier'))
	match.liquipediatiertype = Logic.emptyOr(match.liquipediatiertype, Variables.varDefault('tournament_tier_type'))
	return match
end

function matchFunctions.getVodStuff(match)
	match.stream = match.stream or {}
	match.stream = {
		stream = Logic.emptyOr(match.stream.stream, Variables.varDefault('stream')),
		twitch = Logic.emptyOr(match.stream.twitch or match.twitch, Variables.varDefault('twitch')),
		twitch2 = Logic.emptyOr(match.stream.twitch2 or match.twitch2, Variables.varDefault('twitch2')),
		afreeca = Logic.emptyOr(match.stream.afreeca or match.afreeca, Variables.varDefault('afreeca')),
		afreecatv = Logic.emptyOr(match.stream.afreecatv or match.afreecatv, Variables.varDefault('afreecatv')),
		dailymotion = Logic.emptyOr(match.stream.dailymotion or match.dailymotion, Variables.varDefault('dailymotion')),
		douyu = Logic.emptyOr(match.stream.douyu or match.douyu, Variables.varDefault('douyu')),
		smashcast = Logic.emptyOr(match.stream.smashcast or match.smashcast, Variables.varDefault('smashcast')),
		youtube = Logic.emptyOr(match.stream.youtube or match.youtube, Variables.varDefault('youtube')),
		facebook = Logic.emptyOr(match.stream.facebook or match.facebook, Variables.varDefault('facebook')),
	}
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.lrthread = Logic.emptyOr(match.lrthread, Variables.varDefault('lrthread'))

	match.links = {}
	local links = match.links
	if match.preview then links.preview = match.preview end
	if match.siegegg then links.siegegg = 'https://siege.gg/matches/' .. match.siegegg end
	if match.opl then links.opl = 'https://www.opleague.eu/match/' .. match.opl end
	if match.esl then links.esl = 'https://play.eslgaming.com/match/' .. match.esl end
	if match.faceit then links.faceit = 'https://www.faceit.com/en/rainbow_6/room/' .. match.faceit end
	if match.lpl then links.lpl = 'https://letsplay.live/match/' .. match.lpl end
	if match.r6esports then links.r6esports = 'https://www.r6esports.com.br/en/match/' .. match.r6esports end
	if match.stats then links.stats = match.stats end

	-- apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if not Logic.isEmpty(vodgame) then
			local map = match['map' .. index] or {}
			map.vod = map.vod or vodgame
			match['map' .. index] = map
		end
	end
	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		matchsection = Variables.varDefault('matchsection'),
		lastgame = Variables.varDefault('last_game'),
		comment = match.comment,
		mapveto = matchFunctions.getMapVeto(match),
		mvp = matchFunctions.getMVP(match),
		isconverted = 0
	}
	return match
end

-- Parse the mapVeto input
function matchFunctions.getMapVeto(match)
	if not match.mapveto then return nil end

	match.mapveto = Json.parseIfString(match.mapveto)

	local vetotypes = mw.text.split(match.mapveto.types or '', ',')
	local deciders = mw.text.split(match.mapveto.decider or '', ',')
	local vetostart = match.mapveto.firstpick or ''
	local deciderIndex = 1

	local data = {}
	for index, vetoType in ipairs(vetotypes) do
		vetoType = mw.text.trim(vetoType):lower()
		if not Table.includes(ALLOWED_VETOES, vetoType) then
			return nil -- Any invalid input will not store (ie hide) all vetoes.
		end
		if vetoType == 'decider' then
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

-- Parse MVP input
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

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then

			--retrieve name and icon for teams from team templates
			if opponent.type == 'team' and
				not Logic.isEmpty(opponent.template, match.date) then
					local name, icon, template = opponentFunctions.getTeamNameAndIcon(opponent.template, match.date)
					opponent.template = template or opponent.template
					opponent.name = opponent.name or name
					opponent.icon = opponent.icon or icon
			end

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == 'team' and not Logic.isEmpty(opponent.name) then
				match = matchFunctions.getPlayers(match, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.hasDate then
		local currentUnixTime = os.time(os.date('!*t'))
		local lang = mw.getContentLanguage()
		local matchUnixTime = tonumber(lang:formatDate('U', match.date))
		local threshold = match.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if Logic.readBool(match.finished) then
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

-- Get Playerdata from Vars (get's set in TeamCards)
function matchFunctions.getPlayers(match, opponentIndex, teamName)
	-- match._storePlayers will break after the first empty player. let's make sure we don't leave any gaps.
	local count = 1
	for playerIndex = 1, MAX_NUM_PLAYERS do
		-- parse player
		local player = match['opponent' .. opponentIndex .. '_p' .. playerIndex] or {}
		player = Json.parseIfString(player)
		player.name = player.name or Variables.varDefault(teamName .. '_p' .. playerIndex)
		player.flag = player.flag or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
		player.displayname = player.displayname or Variables.varDefault(teamName .. '_p' .. playerIndex .. 'dn')
		if not Table.isEmpty(player) then
			match['opponent' .. opponentIndex .. '_p' .. count] = player
			count = count + 1
		end
	end
	return match
end

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
function mapFunctions.discardMap(map)
	if map.map == DUMMY_MAP_NAME then
		return true
	else
		return false
	end
end

-- Parse extradata information, particularally info about halfs and operator bans
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		t1firstside = {map.t1firstside, ot = map.t1firstsideot},
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
		t1bans = {map.t1ban1, map.t1ban2},
		t2bans = {map.t2ban1, map.t2ban2},
		pick = map.pick
	}
	return map
end

-- Calculate Score and Winner of the map
-- Use the half information if available
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		if map['t'.. scoreIndex ..'atk'] or map['t'.. scoreIndex ..'def'] then
			score =   (tonumber(map['t'.. scoreIndex ..'atk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'def']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otatk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otdef']) or 0)
		end
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
				obj.status = 'S'
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
	map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)

	return map
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', 'team'))
	map.type = Logic.emptyOr(map.type, Variables.varDefault('tournament_type'))
	map.tournament = Logic.emptyOr(map.tournament, Variables.varDefault('tournament_name'))
	map.tickername = Logic.emptyOr(map.tickername, Variables.varDefault('tournament_ticker_name'))
	map.shortname = Logic.emptyOr(map.shortname, Variables.varDefault('tournament_shortname'))
	map.series = Logic.emptyOr(map.series, Variables.varDefault('tournament_series'))
	map.icon = Logic.emptyOr(map.icon, Variables.varDefault('tournament_icon'))
	map.icondark = Logic.emptyOr(map.iconDark, Variables.varDefault('tournament_icon_dark'))
	map.liquipediatier = Logic.emptyOr(map.liquipediatier, Variables.varDefault('tournament_tier'))
	map.liquipediatiertype = Logic.emptyOr(map.liquipediatiertype, Variables.varDefault('tournament_tier_type'))
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

return CustomMatchGroupInput
