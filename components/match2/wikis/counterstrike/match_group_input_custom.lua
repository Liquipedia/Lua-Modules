---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local MathUtil = require('Module:MathUtil')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local EarningsOf = require('Module:Earnings of')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L', 'D'}
local ALLOWED_VETOES = {'decider', 'pick', 'ban', 'defaultban'}
local NP_MATCH_STATUS = {'cancelled','canceled', 'postponed'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local MAX_NUM_MAPS = 9
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local FEATURED_TIERS = {'S-Tier', 'A-Tier'}
local MIN_EARNINGS_FOR_FEATURED = 200000

local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'
local TODAY = os.date('%Y-%m-%d')

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
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getLinks(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(_, map)
	map = mapFunctions.getTournamentVars(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	local teamTemplateDate = date
	-- If date is epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == EPOCH_TIME_EXTENDED then
		teamTemplateDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			TODAY
		)
	end

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
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
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	if Logic.readBool(data.finished) then
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
			-- A winner can be set in case of a overturned match
			if Logic.isEmpty(data.winner) then
				--CS only has exactly 2 opponents, neither more or less
				if #indexedScores ~= 2 then
					error('Unexpected number of opponents when calculating map winner')
				end
				if tonumber(indexedScores[1].score) > tonumber(indexedScores[2].score) then
					data.winner = 1
				else
					data.winner = 2
				end
				indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
			elseif Logic.isNumeric(data.winner) then
				indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, tonumber(data.winner), 1, 2)
			end
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
		if match['map' .. i] then
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
		if match['map' .. i] then
			if mapFunctions.discardMap(match['map' .. i]) then
				match['map' .. i] = nil
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
			if match['map' .. i] then
				local winner = tonumber(match['map' .. i].winner)
				foundScores = true
				-- Only two opponents in CS
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
			date = EPOCH_TIME_EXTENDED,
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
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault('tournament_liquipediatier'))
	match.liquipediatiertype = Logic.emptyOr(match.liquipediatiertype,
												Variables.varDefault('tournament_liquipediatiertype'))
	match.status = Logic.emptyOr(match.status, Variables.varDefault('tournament_status'))
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_valve_tier'))
	return match
end

function matchFunctions.getLinks(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))
	match.lrthread = Logic.emptyOr(match.lrthread, Variables.varDefault('lrthread'))

	match.links = {}

	local links = match.links

	local platforms = mw.loadData('Module:MatchExternalLinks')

	for _, platform in ipairs(platforms) do
		-- Stat external links inserted in {{Map}}
		if Logic.isNotEmpty(platform) then
			local values = {}
			local platformName = platform['name']
			local plaformPrefixUrl = platform['link']

			if match[platformName] then
				table.insert(values,{plaformPrefixUrl .. match[platformName], 0})
				match[platformName] = nil
			end

			if not Logic.isEmpty(platform['isMapStats']) then
				for i = 1, match.bestof do
					if match['map' .. i] then
						if match['map' .. i][platform.name] then
							table.insert(values, {plaformPrefixUrl .. match['map' .. i][platformName], i})
							match['map' .. i][platform.name] = nil
						end
					end
				end
			else
				if not Logic.isEmpty(platform['max']) then
					for i = 2, platform['max'], 1 do
						if match[platform.name .. i] then
							table.insert(values, {plaformPrefixUrl .. match[platformName .. i], i})
							match[platform.name .. i] = nil
						end
					end
				end
			end

			if #values > 0 then
				links[platformName] = values
			end
		end
	end

	return match
end

function matchFunctions.getMatchStatus(match)
	if match.resulttype == 'np' then
		return match.status
	else
		return nil
	end
end

function matchFunctions.getEarnings(name, year)
	if Logic.isEmpty(name) then
		return 0
	end

	return tonumber(EarningsOf._team(name, {sdate = year .. '-01-01', edate = year .. '-12-31'}))
end

function matchFunctions.isFeatured(match)
	if Table.includes(FEATURED_TIERS, match.liquipediatier) then
		return true
	end
	if Logic.isNotEmpty(match.publishertier) then
		return true
	end

	if not match.hasDate then
		return false
	end

	local opponent1, opponent2 = match.opponent1, match.opponent2
	local year = os.date('%Y')

	if
		opponent1.type == Opponent.team and
		matchFunctions.getEarnings(opponent1.name, year) >= MIN_EARNINGS_FOR_FEATURED
	or
		opponent2.type == Opponent.team and
		matchFunctions.getEarnings(opponent2.name, year) >= MIN_EARNINGS_FOR_FEATURED
	then
		return true
	end

	return false
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		matchsection = Variables.varDefault('matchsection'),
		comment = match.comment,
		mapveto = matchFunctions.getMapVeto(match),
		status = matchFunctions.getMatchStatus(match),
		overturned = Logic.isNotEmpty(match.overturned),
		featured = matchFunctions.isFeatured(match),
		hidden = Logic.readBool(Variables.varDefault('match_hidden'))
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
			table.insert(data, {type = vetoType, team1 = match.mapveto['t1map' .. index],
									team2 = match.mapveto['t2map' .. index]})
		end
	end
	if data[1] then
		data[1].vetostart = vetostart
	end
	return data
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.date)

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getIcon(opponent.template)
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

	-- Handle tournament status for unfinished matches
	if (not Logic.readBool(match.finished)) and Logic.isNotEmpty(match.status) then
		match.finished = match.status
	end

	if Table.includes(NP_MATCH_STATUS, match.finished) then
		match.resulttype = 'np'
		match.status = match.finished
		match.finished = true
	else
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

		if Logic.readBool(match.finished) then
			match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
		end
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

-- Parse extradata information
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
	}
	return map
end

function mapFunctions._getHalfScores(map)
	map.extradata['t1sides'] = {}
	map.extradata['t2sides'] = {}
	map.extradata['t1halfs'] = {}
	map.extradata['t2halfs'] = {}

	local key = ''
	local overtimes = 0

	local function getOpossiteSide(side)
		return side == 'ct' and 't' or 'ct'
	end

	while true do
		local t1Side = map[key .. 't1firstside']
		if Logic.isEmpty(t1Side) or (t1Side ~= 'ct' and t1Side ~= 't') then
			break
		end
		local t2Side = getOpossiteSide(t1Side)

		-- Iterate over two Halfs (In regular time a half is 15 rounds, after that sides switch)
		for _ = 1, 2, 1 do
			if(map[key .. 't1' .. t1Side] and map[key .. 't2' .. t2Side]) then
				table.insert(map.extradata['t1sides'], t1Side)
				table.insert(map.extradata['t2sides'], t2Side)
				table.insert(map.extradata['t1halfs'], tonumber(map[key .. 't1' .. t1Side]) or 0)
				table.insert(map.extradata['t2halfs'], tonumber(map[key .. 't2' .. t2Side]) or 0)
				map[key .. 't1' .. t1Side] = nil
				map[key .. 't2' .. t2Side] = nil
				-- second half (sides switch)
				t1Side, t2Side = t2Side, t1Side
			end
		end

		overtimes = overtimes + 1
		key = 'o' .. overtimes
	end

	return map
end

-- Calculate Score and Winner of the map
-- Use the half information if available
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}

	map = mapFunctions._getHalfScores(map)

	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score
		if Table.includes(ALLOWED_STATUSES, map['score' .. scoreIndex]) then
			score = map['score' .. scoreIndex]
		elseif Logic.isNotEmpty(map.extradata['t' .. scoreIndex .. 'halfs']) then
			score = MathUtil.sum(map.extradata['t' .. scoreIndex .. 'halfs'])
		else
			score = tonumber(map['score' .. scoreIndex])
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

	if map.finished == 'skip' then
		map.resulttype = 'np'
	else
		map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)
	end

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
	map.liquipediatier = Logic.emptyOr(map.liquipediatier, Variables.varDefault('tournament_liquipediatier'))
	map.liquipediatiertype = Logic.emptyOr(map.liquipediatiertype, Variables.varDefault('tournament_liquipediatiertype'))
	map.game = Logic.emptyOr(map.game, Variables.varDefault('tournament_game'))
	return map
end

--
-- opponent related functions
--
function opponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

return CustomMatchGroupInput