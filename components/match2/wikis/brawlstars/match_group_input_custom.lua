---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local BrawlerNames = mw.loadData('Module:BrawlerNames')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local STATUS_TO_WALKOVER = { FF = 'ff', DQ = 'dq', L = 'l' }
local _NOT_PLAYED = {'skip', 'np'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_VODGAMES = 20
local FIRST_PICK_CONVERSION = {
	blue = 1,
	['1'] = 1,
	red = 2,
	['2'] = 2,
}

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
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
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = mapFunctions.getTournamentVars(map)
	map = mapFunctions.getParticipantsData(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, date)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	Opponent.resolve(opponent, date)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
--
-- function to sort out winner/placements
function CustomMatchGroupInput._placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == 'S'
	local op2norm = op2.status == 'S'
	if op1norm then
		if op2norm then
			local op1setwins = CustomMatchGroupInput._getSetWins(op1)
			local op2setwins = CustomMatchGroupInput._getSetWins(op2)
			if op1setwins + op2setwins > 0 then
				return op1setwins > op2setwins
			else
				return tonumber(op1.score) > tonumber(op2.score)
			end
		else return true end
	else
		if op2norm then return false
		elseif op1.status == 'W' then return true
		elseif op1.status == 'DQ' then return false
		elseif op2.status == 'W' then return false
		elseif op2.status == 'DQ' then return true
		else return true end
	end
end

function CustomMatchGroupInput._getSetWins(opp)
	local extradata = opp.extradata or {}
	local set1win = extradata.set1win and 1 or 0
	local set2win = extradata.set2win and 1 or 0
	local set3win = extradata.set3win and 1 or 0
	local sum = set1win + set2win + set3win
	return sum
end

--
-- match related functions
--

function matchFunctions.readDate(matchArgs)
	return matchArgs.date
		and MatchGroupInput.readDate(matchArgs.date)
		or {date = MatchGroupInput.getInexactDate(), dateexact = false}
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

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
		mvp = MatchGroupInput.readMvp(match),
	}
	return match
end

function matchFunctions.getOpponents(args)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false

	local sumscores = {}
	for _, map in Table.iter.pairsByPrefix(args, 'map') do
		if map.winner then
			sumscores[map.winner] = (sumscores[map.winner] or 0) + 1
		end
	end

	local bestof = Logic.emptyOr(args.bestof, Variables.varDefault('bestof', 5))
	bestof = tonumber(bestof) or 5
	Variables.varDefine('bestof', bestof)
	local firstTo = math.ceil(bestof / 2)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = args['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, args.date)

			-- Retrieve icon and legacy name for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getTeamIcon(opponent.template)
				if not opponent.icon then
					opponent.icon, opponent.icondark = opponentFunctions.getLegacyTeamIcon(opponent.template)
				end
				opponent.name = opponent.name or opponentFunctions.getLegacyTeamName(opponent.template)
			end

			opponent.score = opponent.score or sumscores[opponentIndex]

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
				if firstTo <= tonumber(opponent.score) then
					args.finished = true
				end
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
				args.finished = true
			end

			--set Walkover from Opponent status
			args.walkover = args.walkover or STATUS_TO_WALKOVER[opponent.status]

			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == 'team' and not Logic.isEmpty(opponent.name) then
				args = MatchGroupInput.readPlayersOfTeam(args, opponentIndex, opponent.name)
			end
		end
	end

	--set resulttype to 'default' if walkover is set
	if args.walkover then
		args.resulttype = 'default'
	elseif isScoreSet then
		-- if isScoreSet is true we have scores from at least one opponent
		-- in case the other opponent(s) have no score set manually and
		-- no sumscore set we have to set them to 0 now so they are
		-- not displayed as blank
		for _, opponent in pairs(opponents) do
			if
				String.isEmpty(opponent.status)
				and Logic.isEmpty(opponent.score)
			then
				opponent.score = 0
				opponent.status = 'S'
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(args.finished) then
		local currentUnixTime = os.time(os.date('!*t') --[[@as osdateparam]])
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
		-- luacheck: push ignore
		for opponentIndex, opponent in Table.iter.spairs(opponents, CustomMatchGroupInput._placementSortFunction) do
			if placement == 1 then
				args.winner = opponentIndex
			end
			opponent.placement = placement
			args['opponent' .. opponentIndex] = opponent
			placement = placement + 1
		end
	-- luacheck: pop
	-- only apply arg changes otherwise
	else
		for opponentIndex, opponent in pairs(opponents) do
			args['opponent' .. opponentIndex] = opponent
		end
	end
	return args
end

--
-- map related functions
--
function mapFunctions.getExtraData(map)
	local bestof = Logic.emptyOr(map.bestof, Variables.varDefault('map_bestof', 3))
	bestof = tonumber(bestof) or 3
	Variables.varDefine('map_bestof', bestof)
	map.extradata = {
		bestof = bestof,
		comment = map.comment,
		header = map.header,
		maptype = map.maptype,
		firstpick = FIRST_PICK_CONVERSION[string.lower(map.firstpick or '')]
	}

	local bans = {}

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		bans['team' .. opponentIndex] = {}
		for _, ban in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			ban = mapFunctions._cleanBrawlerName(ban)
			table.insert(bans['team' .. opponentIndex], ban)
		end
	end

	map.extradata.bans = Json.stringify(bans)
	map.bestof = bestof

	return map
end

function mapFunctions.getScoresAndWinner(map)
	map.score1 = tonumber(map.score1 or '')
	map.score2 = tonumber(map.score2 or '')
	map.scores = { map.score1, map.score2 }
	if Table.includes(_NOT_PLAYED, string.lower(map.winner or '')) then
		map.winner = 0
		map.resulttype = 'np'
	elseif Logic.isNumeric(map.winner) then
		map.winner = tonumber(map.winner)
	end
	local firstTo = math.ceil( map.bestof / 2 )
	if (map.score1 or 0) >= firstTo then
		map.winner = 1
		map.finished = true
	elseif (map.score2 or 0) >= firstTo then
		map.winner = 2
		map.finished = true
	end

	return map
end

function mapFunctions.getTournamentVars(map)
	map.mode = Logic.emptyOr(map.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInput.getCommonTournamentVars(map)
end

function mapFunctions.getParticipantsData(map)
	local participants = {}

	local maximumPickIndex = 0
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		for _, player, playerIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
			participants[opponentIndex .. '_' .. playerIndex] = {player = player}
		end

		for _, brawler, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'c') do
			brawler = mapFunctions._cleanBrawlerName(brawler)
			participants[opponentIndex .. '_' .. pickIndex] = participants[opponentIndex .. '_' .. pickIndex] or {}
			participants[opponentIndex .. '_' .. pickIndex].brawler = brawler
			if maximumPickIndex < pickIndex then
				maximumPickIndex = pickIndex
			end
		end
	end

	map.extradata.maximumpickindex = maximumPickIndex
	map.participants = participants
	return map
end

function mapFunctions._cleanBrawlerName(brawlerRaw)
	local brawler = BrawlerNames[string.lower(brawlerRaw)]
	if not brawler then
		error('Unsupported brawler input: ' .. brawlerRaw)
	end

	return brawler
end

--
-- opponent related functions
--
function opponentFunctions.getTeamIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

--the following 2 functions are a fallback
--they are only useful if the team template doesn't exist
--in the team template extension
function opponentFunctions.getLegacyTeamName(template)
	local team = Template.expandTemplate(mw.getCurrentFrame(), 'Team', { template })
	team = team:gsub('%&', '')
	team = String.split(team, 'link=')[2]
	team = String.split(team, ']]')[1]
	return team
end

function opponentFunctions.getLegacyTeamIcon(template)
	local iconTemplate = Template.expandTemplate(mw.getCurrentFrame(), 'Team', { template })
	iconTemplate = iconTemplate:gsub('%&', '')
	local icon = String.split(iconTemplate, 'File:')[2]
	local iconDark = String.split(iconTemplate, 'File:')[3] or icon
	icon = String.split(icon, '|')[1]
	iconDark = String.split(iconDark, '|')[1]
	return icon, iconDark
end

return CustomMatchGroupInput
