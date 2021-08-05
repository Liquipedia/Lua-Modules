local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local config = Lua.loadDataIfExists('Module:Match/Config') or {}
local json = require('Module:Json')
local cleanFlag = require('Module:Flags')._CountryName
local FFA
local defaultIcon

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20
local FACTIONS = mw.loadData('Module:Races')
local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local ALLOWED_STATUSES2 = { ['W'] = 'W', ['FF'] = 'FF', ['L'] = 'L', ['DQ'] = 'DQ', ['-'] = 'L' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 30
local MAX_NUM_VODGAMES = 9
local MODES2 = {
	['solo'] = '1',
	['duo'] = '2',
	['trio'] = '3',
	['quad'] = '4',
	['team'] = 'team',
	['literal'] = 'literal',
	}

--[[
Module for converting input args of match group objects into LPDB records. This
module is specific to the StarCraft and StarCraft2 wikis.
]]
local StarCraftMatchGroupInput = {}

-- called from Module:MatchGroup
function StarCraftMatchGroupInput.processMatch(_, match)
	if type(match) == 'string' then
		match = json.parse(match)
	end

	-- process match
	match = StarCraftMatchGroupInput.getDateStuff(match)
	match = StarCraftMatchGroupInput.getTournamentVars(match)
	if match.ffa == 'true' then
		if not FFA then
			FFA = require('Module:DevFlags').matchGroupDev
				and Lua.requireIfExists('Module:MatchGroup/Input/StarCraft/FFA/dev')
				or require('Module:MatchGroup/Input/StarCraft/FFA')
		end
		match = FFA.adjustData(match)
	else
		match = StarCraftMatchGroupInput.adjustData(match)
	end
	match = StarCraftMatchGroupInput.checkFinished(match)
	match = StarCraftMatchGroupInput.getVodStuff(match)
	match = StarCraftMatchGroupInput.getLinks(match)
	match = StarCraftMatchGroupInput.getExtraData(match)

	return match
end

function StarCraftMatchGroupInput.getDateStuff(match)
	local lang = mw.getContentLanguage()
	match.lang = lang
	-- parse date string with abbr
	if not Logic.isEmpty(match.date) then
		local matchString = match.date or ''
		local timezone = String.split(
			String.split(matchString, 'data%-tz%=\"')[2] or '',
			'\"')[1] or String.split(
			String.split(matchString, 'data%-tz%=\'')[2] or '',
			'\'')[1] or ''
		local matchDate = String.explode(matchString, '<', 0):gsub('-', '')
		match.date = matchDate .. timezone
		match.dateexact = match.dateexact == 'true' or String.contains(match.date, '%+') or String.contains(match.date, '%-')
		match.date = lang:formatDate('c', match.date)
		Variables.varDefine('matchDate', match.date)
	else
		local DateVar = Variables.varDefaultMulti('matchDate', 'Match_date', 'date', 'sdate', 'edate', '')
		local missingDates = Variables.varDefault('num_missing_dates', 0) or 0
		match.date = lang:formatDate('c', DateVar .. ' + ' .. missingDates .. ' second')
		match.dateexact = false
		Variables.varDefine('num_missing_dates', Variables.varDefault('num_missing_dates', 0) + 1)
	end

	return match
end

function StarCraftMatchGroupInput.checkFinished(match)
	local lang = match.lang
	if Logic.readBool(match.finished) or (not Logic.isEmpty(match.winner)) then
		match.finished = true
	else
		local currentUnixTime = os.time(os.date('!*t'))
		local matchUnixTime = tonumber(lang:formatDate('U', match.date))
		local threshold = match.dateexact and 30800 or 86400
		if matchUnixTime + threshold < currentUnixTime then
			match.finished = true
		end
	end

	match.lang = nil

	return match
end

function StarCraftMatchGroupInput.getTournamentVars(match)
	match.noQuery = Variables.varDefault('disable_SMW_storage', 'false')
	match.cancelled = Logic.emptyOr(match.cancelled, Variables.varDefault('cancelled tournament', 'false'))
	match['type'] = Logic.emptyOr(match['type'], Variables.varDefault('tournament_type'))
	match.tournament = Logic.emptyOr(match.tournament, Variables.varDefault('tournament_name'))
	match.tickername = Logic.emptyOr(match.tickername, Variables.varDefault('tournament_ticker_name'))
	match.shortname = Logic.emptyOr(match.shortname, Variables.varDefault('tournament_shortname'))
	match.series = Logic.emptyOr(match.series, Variables.varDefault('tournament_series'))
	match.icon = Logic.emptyOr(match.icon, Variables.varDefault('tournament_icon'))
	match.liquipediatier = Logic.emptyOr(match.liquipediatier, Variables.varDefault('tournament_tier'))
	match.liquipediatiertype = Logic.emptyOr(match.liquipediatiertype, Variables.varDefault('tournament_tiertype'))
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))
	Variables.varDefine('headtohead', match.headtohead)
	match.featured = Logic.emptyOr(match.featured, Variables.varDefault('featured'))
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof'))
	Variables.varDefine('bestof', match.bestof)
	return match
end

function StarCraftMatchGroupInput.getVodStuff(match)
	match.stream = match.stream or {}
	match.stream = json.stringify({
		stream = Logic.emptyOr(match.stream, Variables.varDefault('stream')),
		twitch = Logic.emptyOr(match.twitch, Variables.varDefault('twitch')),
		twitch2 = Logic.emptyOr(match.twitch2, Variables.varDefault('twitch2')),
		afreeca = Logic.emptyOr(match.afreeca, Variables.varDefault('afreeca')),
		afreecatv = Logic.emptyOr(match.afreecatv, Variables.varDefault('afreecatv')),
		dailymotion = Logic.emptyOr(match.dailymotion, Variables.varDefault('dailymotion')),
		douyu = Logic.emptyOr(match.douyu, Variables.varDefault('douyu')),
		smashcast = Logic.emptyOr(match.smashcast, Variables.varDefault('smashcast')),
		youtube = Logic.emptyOr(match.youtube, Variables.varDefault('youtube')),
		trovo = Logic.emptyOr(match.trovo, Variables.varDefault('trovo'))
	})
	match.vod = Logic.emptyOr(match.vod)

	return match
end

function StarCraftMatchGroupInput.getLinks(match)
	match.links = json.stringify({
		preview = match.preview,
		preview2 = match.preview2,
		interview = match.interview,
		interview2 = match.interview2,
		review = match.review,
		recap = match.recap,
		lrthread = match.lrthread,
	})
	return match
end

function StarCraftMatchGroupInput.getExtraData(match)
	local extradata
	if match.ffa == 'true' then
		extradata = FFA.getExtraData(match)
	else
		extradata = {
			noQuery = match.noQuery,
			matchsection = Variables.varDefault('matchsection'),
			comment = match.comment,
			featured = match.featured,
			veto1 = StarCraftMatchGroupInput.getVetoMap(match.veto1),
			veto2 = StarCraftMatchGroupInput.getVetoMap(match.veto2),
			veto3 = StarCraftMatchGroupInput.getVetoMap(match.veto3),
			veto4 = StarCraftMatchGroupInput.getVetoMap(match.veto4),
			veto5 = StarCraftMatchGroupInput.getVetoMap(match.veto5),
			veto6 = StarCraftMatchGroupInput.getVetoMap(match.veto6),
			veto1by = (match.vetoplayer1 or '') ~= '' and match.vetoplayer1 or match.vetoopponent1,
			veto2by = (match.vetoplayer2 or '') ~= '' and match.vetoplayer2 or match.vetoopponent2,
			veto3by = (match.vetoplayer3 or '') ~= '' and match.vetoplayer3 or match.vetoopponent3,
			veto4by = (match.vetoplayer4 or '') ~= '' and match.vetoplayer4 or match.vetoopponent4,
			veto5by = (match.vetoplayer5 or '') ~= '' and match.vetoplayer5 or match.vetoopponent5,
			veto6by = (match.vetoplayer6 or '') ~= '' and match.vetoplayer6 or match.vetoopponent6,
			contestname = (match.contestname or '') ~= '' and (match.contestname .. ' Bracket Contest') or nil,
			subGroup1header = StarCraftMatchGroupInput.getSubGroupHeader(1, match),
			subGroup2header = StarCraftMatchGroupInput.getSubGroupHeader(2, match),
			subGroup3header = StarCraftMatchGroupInput.getSubGroupHeader(3, match),
			subGroup4header = StarCraftMatchGroupInput.getSubGroupHeader(4, match),
			subGroup5header = StarCraftMatchGroupInput.getSubGroupHeader(5, match),
			subGroup6header = StarCraftMatchGroupInput.getSubGroupHeader(6, match),
			subGroup7header = StarCraftMatchGroupInput.getSubGroupHeader(7, match),
			subGroup8header = StarCraftMatchGroupInput.getSubGroupHeader(8, match),
			subGroup9header = StarCraftMatchGroupInput.getSubGroupHeader(9, match),
			headtohead = match.headtohead,
			ffa = 'false',
		}
	end

	match.extradata = json.stringify(extradata)
	return match
end

function StarCraftMatchGroupInput.getVetoMap(map)
	return (map ~= nil) and mw.ext.TeamLiquidIntegration.resolve_redirect(map) or nil
end

function StarCraftMatchGroupInput.getSubGroupHeader(index, match)
	local out = match['subGroup' .. index .. 'header'] or ''
	if out == '' then
		out = match['subgroup' .. index .. 'header'] or ''
		if out == '' then
			out = match['submatch' .. index .. 'header'] or ''
			if out == '' then
				return nil
			end
		end
	end
	return out
end

function StarCraftMatchGroupInput.adjustData(match)
	--parse opponents + set base sumscores + determine match mode
	match.mode = ''
	match = StarCraftMatchGroupInput.OpponentInput(match)

	--main processing done here
	local subgroup = 0
	for i = 1, MAX_NUM_MAPS do
		if match['map' .. i] then
			--parse the stringified map arguments to be a table again
			match['map' .. i] = json.parseIfString(match['map' .. i])
		else
			break
		end
		if (match['map' .. i].winner or '') ~= '' or (match['map' .. i].map or '') ~= '' then
			match, subgroup = StarCraftMatchGroupInput.MapInput(match, i, subgroup)
		else
			match['map' .. i] = nil
			break
		end
	end

	--apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if (not Logic.isEmpty(vodgame)) and (not Logic.isEmpty(match['map' .. index])) then
			match['map' .. index].vod = match['map' .. index].vod or vodgame
		end
	end

	if string.find(match.mode, 'team') then
		match = StarCraftMatchGroupInput.SubMatchStructure(match)
	else
		for i = 1, MAX_NUM_MAPS do
			if match['map' .. i] then
				--stringify maps if not team match (for team matches it is done via the above function)
				match['map' .. i].participants = json.stringify(match['map' .. i].participants)
				match['map' .. i] = json.stringify(match['map' .. i])
			else
				break
			end
		end
	end

	match = StarCraftMatchGroupInput.MatchWinnerProcessing(match)

	--Bracket Contest Handling
	if match.contest and tostring(match.contest.finished) == '1' then
		match = StarCraftMatchGroupInput.processContest(match)
	end

	return match
end

--[[

Misc. MatchInput functions
--> Winner, Walkover, Placement, Resulttype, Status
--> Sub-Match Structure

]]--
function StarCraftMatchGroupInput.MatchWinnerProcessing(match)
	local bestof = tonumber(match.bestof or 99) or 99
	local walkover = match.walkover or ''
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		if not Logic.isEmpty(match['opponent' .. opponentIndex]) then
			--determine opponent scores, status and placement
			--determine MATCH winner, resulttype and walkover
			--the following ignores the possibility of > 2 opponents
			if walkover ~= '' then
				if Logic.isNumeric(walkover) then
					walkover = tonumber(walkover)
					if walkover == opponentIndex then
						match.winner = opponentIndex
						match.walkover = 'L'
						match['opponent' .. opponentIndex].status = 'W'
					elseif walkover == 0 then
						match.winner = 0
						match.walkover = 'L'
						match['opponent' .. opponentIndex].status = 'L'
					else
						local upper = string.upper(match['opponent' .. opponentIndex].score or '')
						match['opponent' .. opponentIndex].status = ALLOWED_STATUSES2[upper] or 'L'
					end
				elseif Table.includes(ALLOWED_STATUSES, string.upper(walkover)) then
					if tonumber(match.winner or 0) == opponentIndex then
						match['opponent' .. opponentIndex].status = 'W'
					else
						match['opponent' .. opponentIndex].status = ALLOWED_STATUSES2[string.upper(walkover)] or 'L'
					end
				else
					local upper = string.upper(match['opponent' .. opponentIndex].score or '')
					match['opponent' .. opponentIndex].status = ALLOWED_STATUSES2[upper] or 'L'
					match.walkover = 'L'
				end
				match['opponent' .. opponentIndex].score = -1
				match.finished = 'true'
				match.resulttype = 'default'
			elseif Logic.readBool(match.cancelled) then
				match.resulttype = 'np'
				match.finished = 'true'
				match['opponent' .. opponentIndex].score = -1
			elseif ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score or '')] then
				if string.upper(match['opponent' .. opponentIndex].score) == 'W' then
					match.winner = opponentIndex
					match.resulttype = 'default'
					match.finished = 'true'
					match['opponent' .. opponentIndex].score = -1
					match['opponent' .. opponentIndex].status = 'W'
				else
					match.resulttype = 'default'
					match.finished = 'true'
					match.walkover = ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score)]
					local upper = string.upper(match['opponent' .. opponentIndex].score)
					match['opponent' .. opponentIndex].status = ALLOWED_STATUSES2[upper]
					match['opponent' .. opponentIndex].score = -1
				end
			else
				match['opponent' .. opponentIndex].status = 'S'
				match['opponent' .. opponentIndex].score = tonumber(match['opponent' .. opponentIndex].score or '') or
					tonumber(match['opponent' .. opponentIndex].sumscore) or -1

				if match['opponent' .. opponentIndex].score > bestof / 2 then
					match.finished = 'true'
					match.winner = tonumber(match.winner or '') or opponentIndex
				elseif match.winner == 'draw' or tonumber(match.winner) == 0 or
						(match.opponent1 == bestof / 2 and match.opponent1 == match.opponent2) then
					match.finished = 'true'
					match.winner = 0
					match.resulttype = 'draw'
				end
			end
			if tostring(match.winner) == tostring(opponentIndex) or
					match.resulttype == 'draw' or
					match['opponent' .. opponentIndex].score == bestof / 2 then
				match['opponent' .. opponentIndex].placement = 1
			else
				match['opponent' .. opponentIndex].placement = 2
			end

			--stringify player data
			for key, _ in ipairs(match['opponent' .. opponentIndex].match2players) do
				match['opponent' .. opponentIndex].match2players[key].extradata =
					json.stringify(match['opponent' .. opponentIndex].match2players[key].extradata)
			end
			match['opponent' .. opponentIndex].match2players = json.stringify(match['opponent' .. opponentIndex].match2players)

			--stringify opponent extradata
			match['opponent' .. opponentIndex].extradata = json.stringify(match['opponent' .. opponentIndex].extradata)

			--stringify opponents
			match['opponent' .. opponentIndex] = json.stringify(match['opponent' .. opponentIndex])
		else
			break
		end
	end

	return match
end

function StarCraftMatchGroupInput.SubMatchStructure(match)
	local SubMatches = {}
	local j = 0

	for i = 1, MAX_NUM_MAPS do
		if not Logic.isEmpty(match['map' .. i]) then
			j = i
			local participants = match['map' .. i].participants or {}
			local opp = {}

			if match['map' .. i].mode == '1v1' then
				for key, item in pairs(participants) do
					local temp = String.split(key, '_')
					opp[temp[1]] = item.player
				end
			end

			local k = match['map' .. i].subgroup
			--create a new sub-match if necessary
			SubMatches[k] = SubMatches[k] or {
				date = match['map' .. i].date,
				game = match['map' .. i].game,
				liquipediatier = match['map' .. i].liquipediatier,
				liquipediatiertype = match['map' .. i].liquipediatiertype,
				participants = json.stringify(participants),
				mode = match['map' .. i].mode,
				resulttype = 'submatch',
				subgroup = k,
				extradata = json.stringify({
					header = (match['subGroup' .. k .. 'header'] or '') ~= '' and match['subGroup' .. k .. 'header'] or
						(match['subgroup' .. k .. 'header'] or '') ~= '' and match['subgroup' .. k .. 'header'] or
						match['submatch' .. k .. 'header'],
					noQuery = match.noQuery,
					matchsection = Variables.varDefault('matchsection'),
					featured = match.featured,
					isSubMatch = 'true',
					opponent1 = opp['1'],
					opponent2 = opp['2']
				}),
				['type'] = match['type'],
				scores = { 0, 0 },
				winner = 0
			}
			--adjust sub-match scores
			if tonumber(match['map' .. i].winner) == 1 then
				SubMatches[k].scores[1] = SubMatches[k].scores[1] + 1
			elseif tonumber(match['map' .. i].winner) == 2 then
				SubMatches[k].scores[2] = SubMatches[k].scores[2] + 1
			end
			--stringify map
			match['map' .. i].participants = json.stringify(match['map' .. i].participants)
			match['map' .. i] = json.stringify(match['map' .. i])
		else
			break
		end
	end

	for k, sub in ipairs(SubMatches) do
		--get winner
		if sub.scores[1] > sub.scores[2] then
			sub.winner = 1
		elseif sub.scores[2] > sub.scores[1] then
			sub.winner = 2
		end

		match['map' .. (j + k)] = sub
	end

	return match
end

--[[

OpponentInput functions

]]--
function StarCraftMatchGroupInput.OpponentInput(match)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		if not Logic.isEmpty(match['opponent' .. opponentIndex]) then
			--parse the stringified opponent arguments to be a table again
			match['opponent' .. opponentIndex] = json.parseIfString(match['opponent' .. opponentIndex])

			--fix legacy winner
			if (match['opponent' .. opponentIndex].win or '') ~= '' then
				if (match.winner or '') == '' then
					match.winner = tostring(opponentIndex)
				else
					match.winner = '0'
				end
				match['opponent' .. opponentIndex].win = nil
			end

			--opponent processing (first part)
			--sort out extradata
			match['opponent' .. opponentIndex].extradata = {
				advantage = match['opponent' .. opponentIndex].advantage,
				score2 = match['opponent' .. opponentIndex].score2,
				isarchon = match['opponent' .. opponentIndex].isarchon
			}

			--process input depending on type
			if match['opponent' .. opponentIndex]['type'] == 'solo' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessSoloOpponentInput(match['opponent' .. opponentIndex])
			elseif match['opponent' .. opponentIndex]['type'] == 'duo' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessDuoOpponentInput(match['opponent' .. opponentIndex])
			elseif match['opponent' .. opponentIndex]['type'] == 'trio' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessOpponentInput(match['opponent' .. opponentIndex], 3)
			elseif match['opponent' .. opponentIndex]['type'] == 'quad' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessOpponentInput(match['opponent' .. opponentIndex], 4)
			elseif match['opponent' .. opponentIndex]['type'] == 'team' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessTeamOpponentInput(match['opponent' .. opponentIndex], match.date)
			elseif match['opponent' .. opponentIndex]['type'] == 'literal' then
				match['opponent' .. opponentIndex] =
					StarCraftMatchGroupInput.ProcessLiteralOpponentInput(match['opponent' .. opponentIndex])
			else
				error('Unsupported Opponent Type')
			end

			--mark match as noQuery if it contains BYE/TBD/TBA/'' or Literal opponents
			local pltemp = string.lower(match['opponent' .. opponentIndex].name or '')
			if pltemp == '' or pltemp == 'tbd' or pltemp == 'tba' or pltemp == 'bye' or
					match['opponent' .. opponentIndex]['type'] == 'literal' then
				match.noQuery = 'true'
			end

			--set initial opponent sumscore
			match['opponent' .. opponentIndex].sumscore =
				tonumber(match['opponent' .. opponentIndex].extradata.advantage or '') or ''

			local mode = MODES2[match['opponent' .. opponentIndex]['type']]
			if mode == '2' and match['opponent' .. opponentIndex].extradata.isarchon == 'true' then
				mode = 'Archon'
			end

			match.mode = match.mode .. (opponentIndex ~= 1 and '_' or '') .. mode
		else
			break
		end
	end

	return match
end

function StarCraftMatchGroupInput.ProcessSoloOpponentInput(opp)
	local name = (opp.name or '') ~= '' and opp.name or (opp.p1 or '') ~= '' and opp.p1
		or opp[1] or ''
	local link = mw.ext.TeamLiquidIntegration.resolve_redirect((opp.link or '') ~= '' and opp.link
		or Variables.varDefault(name .. '_page') or name)
	local race = (opp.race or '') ~= '' and opp.race or Variables.varDefault(name .. '_race') or ''
	local players = {}
	local flag = (opp.flag or '') ~= '' and opp.flag or Variables.varDefault(name .. '_flag')
	players[1] = {
		displayname = name,
		name = link,
		flag = cleanFlag(flag),
		extradata = { faction = FACTIONS[string.lower(race)] or 'u' }
	}

	local opp2 = {
		type = opp['type'],
		name = link,
		score = opp.score,
		extradata = opp.extradata,
		match2players = players
	}

	return opp2
end

function StarCraftMatchGroupInput.ProcessDuoOpponentInput(opp)
	opp.p1 = opp.p1 or ''
	opp.p2 = opp.p2 or ''
	opp.link1 = mw.ext.TeamLiquidIntegration.resolve_redirect((opp.p1link or '') ~= ''
		and opp.p1link or Variables.varDefault(opp.p1 .. '_page') or opp.p1)
	opp.link2 = mw.ext.TeamLiquidIntegration.resolve_redirect((opp.p2link or '') ~= ''
		and opp.p2link or Variables.varDefault(opp.p2 .. '_page') or opp.p2)
	if opp.extradata.isarchon == 'true' then
		opp.p1race = FACTIONS[string.lower(opp.race or '')] or 'u'
		opp.p2race = opp.p1race
	else
		opp.p1race = FACTIONS[string.lower((opp.p1race or '') ~= '' and
			opp.p1race or Variables.varDefault(opp.p1 .. '_race') or '')] or 'u'
		opp.p2race = FACTIONS[string.lower((opp.p2race or '') ~= '' and
			opp.p2race or Variables.varDefault(opp.p2 .. '_race') or '')] or 'u'
	end

	local players = {}
	for i = 1, 2 do
		local flag = (opp['p' .. i .. 'flag'] or '') ~= '' and opp['p' .. i .. 'flag'] or
			Variables.varDefault(opp['p' .. i] .. '_flag')
		players[i] = {
			displayname = opp['p' .. i],
			name = opp['link' .. i],
			flag = cleanFlag(flag),
			extradata = { faction = FACTIONS[string.lower(opp['p' .. i .. 'race'])] or 'u' }
		}
	end
	local name = opp.link1 .. ' / ' .. opp.link2

	local opp2 = {
		type = opp['type'],
		name = name,
		score = opp.score,
		extradata = opp.extradata,
		match2players = players
	}

	return opp2
end

function StarCraftMatchGroupInput.ProcessOpponentInput(opp, playernumber)
	local name = ''

	local players = {}
	for i = 1, playernumber do
		local Pname = opp['p' .. i] or ''
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect((opp['p' .. i .. 'link'] or '') ~= ''
			and opp['p' .. i .. 'link'] or Variables.varDefault(Pname .. '_page') or Pname)
		local race = (opp['p' .. i .. 'race'] or '') ~= '' and opp['p' .. i .. 'race'] or
			Variables.varDefault(Pname .. '_race') or ''

		name = name .. (i ~= 1 and ' / ' or '') .. link
		local flag = (opp['p' .. i .. 'flag'] or '') ~= '' and opp['p' .. i .. 'flag'] or
				Variables.varDefault((opp['p' .. i] or '') .. '_flag')

		players[i] = {
			displayname = Pname,
			name = link,
			flag = cleanFlag(flag),
			extradata = { faction = FACTIONS[string.lower(race)] or 'u' }
		}
	end

	local opp2 = {
		type = opp['type'],
		name = name,
		score = opp.score,
		extradata = opp.extradata,
		match2players = players
	}

	return opp2
end

function StarCraftMatchGroupInput.ProcessLiteralOpponentInput(opp)
	return {
		type = opp['type'],
		name = opp[1],
		score = opp.score,
		extradata = opp.extradata,
		match2players = {}
	}
end

function StarCraftMatchGroupInput.getPlayersLegacy(playerData)
	local players = {}
	playerData = json.parseIfString(playerData) or {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		local name = mw.ext.TeamLiquidIntegration.resolve_redirect((playerData['p' .. playerIndex .. 'link'] or '') ~= ''
			and playerData['p' .. playerIndex .. 'link'] or playerData['p' .. playerIndex] or '')
		if name ~= '' then
			players[playerIndex] = {
				name = name,
				displayname = playerData['p' .. playerIndex],
				flag = cleanFlag(playerData['p' .. playerIndex .. 'flag']),
				extradata = {
					faction = playerData['p' .. playerIndex .. 'race'],
					position = playerIndex
				}
			}
		else
			break
		end
	end
	return players
end

function StarCraftMatchGroupInput.getPlayers(teamName)
	local players = {}
	for playerIndex = 1, MAX_NUM_PLAYERS do
		local name = Variables.varDefault(teamName .. '_p' .. playerIndex)
		if not Logic.isEmpty(name) then
			local flag = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'flag')
			players[playerIndex] = {
				name = name,
				displayname = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'display'),
				flag = cleanFlag(flag),
				extradata = { faction = Variables.varDefault(teamName .. '_p' .. playerIndex .. 'race') }
			}
		else
			break
		end
	end
	return players
end

function StarCraftMatchGroupInput.ProcessTeamOpponentInput(opp, date)
	local customTeam = Logic.readBool(opp.default) or Logic.readBool(opp.defaulticon) or Logic.readBool(opp.custom)
	local name
	local icon

	if customTeam then
		if not defaultIcon then
			defaultIcon = require('Module:Brkts/WikiSpecific').defaultIcon
		end
		opp.template = 'default'
		icon = defaultIcon
		name = (opp.link or '') ~= '' and opp.link or (opp.name or '') ~= '' and opp.name or opp[1] or ''
		opp.extradata = opp.extradata or {}
		opp.extradata.display = (opp.name or '') ~= '' and opp.name or opp[1] or ''
		opp.extradata.short = (opp.short or '') ~= '' and opp.short or (opp.name or '') ~= '' and opp.name or opp[1] or ''
		opp.extradata.bracket = (opp.bracket or '') ~= '' and opp.bracket
			or (opp.name or '') ~= '' and opp.name or opp[1] or ''
	else
		opp.template = string.lower((opp.template or '') ~= '' and opp.template or opp[1] or '')
		if opp.template == '' then
			opp.template = 'tbd'
		end
		name, icon, opp.template = StarCraftMatchGroupInput.processTeamTemplateInput(opp.template, date)
	end
	name = mw.ext.TeamLiquidIntegration.resolve_redirect(name or '')
	local players = StarCraftMatchGroupInput.getPlayers(name)
	if Logic.isEmpty(players) then
		players = StarCraftMatchGroupInput.getPlayersLegacy(opp.players)
	end

	return {
		icon = icon,
		template = opp.template,
		['type'] = opp['type'],
		name = name,
		score = opp.score,
		extradata = opp.extradata,
		match2players = players
	}
end

function StarCraftMatchGroupInput.processTeamTemplateInput(template, date)
	local icon, name
	template = string.lower(template or ''):gsub('_', ' ')
	if template ~= '' and template ~= 'noteam' and
		mw.ext.TeamTemplate.teamexists(template) then

		local templateData = mw.ext.TeamTemplate.raw(template, date)
		icon = templateData.image
		if icon == '' then
			icon = templateData.legacyimage
		end
		name = templateData.page
		template = templateData.templateName or template
	end

	return name, icon, template
end

--[[

MapInput functions

]]--
function StarCraftMatchGroupInput.MapInput(match, i, subgroup)
	--redirect maps
	if match['map' .. i].map ~= 'TBD' then
		match['map' .. i].map = mw.ext.TeamLiquidIntegration.resolve_redirect(match['map' .. i].map or '')
	end

	--set initial extradata for maps
	match['map' .. i].extradata = {
		comment = match['map' .. i].comment or '',
		header = match['map' .. i].header or '',
		noQuery = match.noQuery,
		isSubMatch = 'false'
	}

	--inherit stuff from match data
	match['map' .. i]['type'] = match['type']
	match['map' .. i].liquipediatier = match.liquipediatier
	match['map' .. i].liquipediatiertype = match.liquipediatiertype
	match['map' .. i].game = match.game
	match['map' .. i].date = match.date

	--determine score, resulttype, walkover and winner
	match['map' .. i] = StarCraftMatchGroupInput.MapWinnerProcessing(match['map' .. i])

	--get participants data for the map + get map mode + winnerrace and loserrace
	--(w/l race stuff only for 1v1 maps)
	match['map' .. i] = StarCraftMatchGroupInput.ProcessPlayerMapData(match['map' .. i], match, 2)

	--set sumscore to 0 if it isn't a number
	if match.opponent1.sumscore == '' then
		match.opponent1.sumscore = 0
	end
	if match.opponent2.sumscore == '' then
		match.opponent2.sumscore = 0
	end

	--adjust sumscore for winner opponent
	if (tonumber(match['map' .. i].winner or 0) or 0) > 0 then
		match['opponent' .. match['map' .. i].winner].sumscore =
			match['opponent' .. match['map' .. i].winner].sumscore + 1
	end

	--handle subgroup stuff if team match
	if string.find(match.mode, 'team') then
		match['map' .. i].subgroup = tonumber(match['map' .. i].subgroup or '')
		if match['map' .. i].subgroup then
			subgroup = match['map' .. i].subgroup
		else
			subgroup = subgroup + 1
			match['map' .. i].subgroup = subgroup
		end
	end

	return match, subgroup
end

function StarCraftMatchGroupInput.MapWinnerProcessing(map)
	map.scores = {}
	local manual_scores = false
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		local obj = {}
		if not Logic.isEmpty(score) then
			manual_scores = true
			score = ALLOWED_STATUSES2[score] or score
			if Logic.isNumeric(score) then
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

	if manual_scores then
		for scoreIndex, _ in Table.iter.spairs(indexedScores, StarCraftMatchGroupInput.placementSortFunction) do
			if not tonumber(map.winner or '') then
				map.winner = scoreIndex
			else
				break
			end
		end
	else
		if (map.walkover or '') ~= '' then
			if map.walkover == '1' then
				map.winner = '1'
			elseif map.walkover == '2' then
				map.winner = '2'
			elseif map.walkover == '0' then
				map.winner = '0'
			end
			map.walkover = Table.includes(ALLOWED_STATUSES, map.walkover) and map.walkover or 'L'
			map.scores = { -1, -1 }
			map.resulttype = 'default'
		elseif map.winner == 'skip' then
			map.scores = { 0, 0 }
			map.scores = { -1, -1 }
			map.resulttype = 'np'
		elseif map.winner == '1' then
			map.scores = { 1, 0 }
		elseif map.winner == '2' then
			map.scores = { 0, 1 }
		elseif map.winner == '0' or map.winner == 'draw' then
			map.scores = { 0.5, 0.5 }
			map.resulttype = 'draw'
		end
	end
	return map
end

function StarCraftMatchGroupInput.ProcessPlayerMapData(map, match, OppNumber)
	local participants = {}
	local map_mode = ''
	local raceOP = {}
	local PL = {}

	for i = 1, OppNumber do
		local number = 0
		if match['opponent' .. i]['type'] == 'team' then
			local players = match['opponent' .. i].match2players
			if players == {} then
				break
			end

			local tbds = 0

			local PlayerData = {}
			for j = 1, 4 do
				if not Logic.isEmpty(map['t' .. i .. 'p' .. j]) then
					if map['t' .. i .. 'p' .. j] ~= 'TBD' and map['t' .. i .. 'p' .. j] ~= 'TBA' then
						map['t' .. i .. 'p' .. j] = mw.ext.TeamLiquidIntegration.resolve_redirect(map['t' .. i .. 'p' .. j])

						if map['opponent' .. i .. 'archon'] == 'true' then
							PlayerData[map['t' .. i .. 'p' .. j]] = {
								faction = FACTIONS[string.lower((map['t' .. i .. 'race'] or '') ~= '' and map['t' .. i .. 'race'] or
									(map['opponent' .. i .. 'race'] or '') ~= '' and map['opponent' .. i .. 'race'] or
									(map['t' .. i .. 'p' .. j .. 'race'] or '') ~= '' and map['t' .. i .. 'p' .. j .. 'race']
									or 'u')] or 'u',
								position = j
							}
						else
							PlayerData[map['t' .. i .. 'p' .. j]] = {
								faction = FACTIONS[string.lower((map['t' .. i .. 'p' .. j .. 'race'] or '') ~= '' and
									map['t' .. i .. 'p' .. j .. 'race'] or 'u')] or 'u',
								position = j
							}
						end
					else
						tbds = tbds + 1
					end
				else
					break
				end
			end

			for key, item in pairs(players) do
				if item and PlayerData[item.name] then
					number = number + 1
					local faction = (PlayerData[item.name].faction ~= 'u') and PlayerData[item.name].faction or
						item.extradata.faction or 'u'
					raceOP[i] = faction
					PL[i] = item.name
					participants[i .. '_' .. key] = {
						faction = faction,
						player = item.name,
						position = PlayerData[item.name].position,
						flag = cleanFlag(item.flag),
					}
				end
			end

			local num = #players

			for r = 1, tbds do
				number = number + 1
				participants[i .. '_' .. (num + r)] = {
						faction = 'u',
						player = 'TBD'
					}
			end

			if number == 2 and map['opponent' .. i .. 'archon'] == 'true' then
				number = 'Archon'
			elseif number == 2 and map['opponent' .. i .. 'duoSpecial'] == 'true' then
				number = '2S'
			elseif number == 4 and map['opponent' .. i .. 'quadSpecial'] == 'true' then
				number = '4S'
			end
		elseif match['opponent' .. i]['type'] == 'literal' then
			number = 'Literal'
		elseif match['opponent' .. i]['type'] == 'duo' and match['opponent' .. i].extradata.isarchon == 'true' then
			number = 'Archon'
			local players = match['opponent' .. i].match2players
			if players == {} then
				break
			else
				local faction = string.lower((map['opponent' .. i .. 'race'] or '') ~= '' and map['opponent' .. i .. 'race'] or
					(map['race' .. i] or '') ~= '' and map['race' .. i] or players[1].extradata.faction or 'u')
				participants[i .. '_1'] = {
					faction = FACTIONS[faction] or 'u',
					player = players[1].name
				}
				raceOP[i] = participants[i .. '_1'].faction
				PL[i] = players[1].name

				participants[i .. '_2'] = {
					faction = FACTIONS[faction] or 'u',
					player = players[2].name
				}
			end
		else
			number = tonumber(MODES2[match['opponent' .. i]['type']])
			local players = match['opponent' .. i].match2players
			if players == {} then
				break
			else
				local faction = string.lower((map['t' .. i .. 'p1race'] or '') ~= '' and map['t' .. i .. 'p1race'] or
					(map['race' .. i] or '') ~= '' and map['race' .. i] or 'u')
				participants[i .. '_1'] = {
					faction = FACTIONS[faction] or players[1].extradata.faction or 'u',
					player = players[1].name
				}
				raceOP[i] = participants[i .. '_1'].faction
				PL[i] = players[1].name
				for j = 2, number do
					faction = string.lower((map['t' .. i .. 'p' .. j .. 'race'] or '') ~= '' and
						map['t' .. i .. 'p' .. j .. 'race'] or 'u')
					participants[i .. '_' .. j] = {
						faction = FACTIONS[faction] or players[j].extradata.faction or 'u',
						player = players[j].name
					}
				end
			end
		end
		map_mode = map_mode .. (i ~= 1 and 'v' or '') .. number

		if map_mode == '1v1' and OppNumber == 2 then
			if tonumber(map.winner or 0) == 1 then
				map.extradata.winnerrace = raceOP[1]
				map.extradata.loserrace = raceOP[2]
			elseif tonumber(map.winner or 0) == 2 then
				map.extradata.winnerrace = raceOP[2]
				map.extradata.loserrace = raceOP[1]
			end
			map.extradata.opponent1 = PL[1]
			map.extradata.opponent2 = PL[2]
		end
	end

	map.mode = map_mode

	map.participants = participants
	map.extradata = json.stringify(map.extradata)
	return map
end

-- function to sort out winner/placements
function StarCraftMatchGroupInput.placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	local op1norm = op1.status == 'S'
	local op2norm = op2.status == 'S'
	if op1norm then
		if op2norm then
			return tonumber(op1.score) > tonumber(op2.score)
		else return true end
	else
		if op2norm then return false
		elseif op1.status == 'W' then return true
		elseif op1.status == 'DQ' then return false
		elseif op1.status == 'FF' then return false
		elseif op1.status == 'L' then return false
		elseif op2.status == 'W' then return false
		elseif op2.status == 'DQ' then return true
		elseif op2.status == 'FF' then return true
		elseif op2.status == 'L' then return true
		else return true end
	end
end

--[[

Bracket Contests function

]]--
function StarCraftMatchGroupInput.processContest(match)
	local points = tonumber(Variables.varDefault('contestPoints', 0)) or 0
	local score1 = {}
	local score2 = {}
	local Rscore1 = {}
	local Rscore2 = {}
	for opponentIndex = 1, 2 do
		match['opponent' .. opponentIndex] = json.parseIfString(match['opponent' .. opponentIndex])
		match['opponent' .. opponentIndex].extradata = json.parseIfString(match['opponent' .. opponentIndex].extradata)
		local Opp = match['opponent' .. opponentIndex]
		local ResultOpp = match.contest.opponents[opponentIndex]
		ResultOpp.extradata = ResultOpp.extradata or {}
		if ResultOpp.name ~= Opp.name then
			break
		end
		score1[opponentIndex] = tonumber(Opp.score or 0) or 0
		score2[opponentIndex] = tonumber(Opp.extradata.score2 or 0) or 0
		Rscore1[opponentIndex] = tonumber(ResultOpp.score or 0) or 0
		Rscore2[opponentIndex] = tonumber(ResultOpp.extradata.score2 or 0) or 0

		if score1[opponentIndex] == Rscore1[opponentIndex] and score2[opponentIndex] == Rscore2[opponentIndex] then
			match['opponent' .. opponentIndex].extradata.contest =
				'<i class="fa fa-check forest-green-text" aria-hidden="true"></i>'
		else
			match['opponent' .. opponentIndex].extradata.contest = '&nbsp;'
		end
	end

	if match.opponent1.extradata.contest ~= '&nbsp;' and match.opponent1.extradata.contest ~= '&nbsp;' then
		points = points + match.contest.points.score
	elseif score1[1] - score1[2] + Rscore1[2] - Rscore1[1] == 0 and
			score2[1] - score2[2] + Rscore2[2] - Rscore2[1] == 0 then
		points = points + match.contest.points.diff
	elseif tostring(match.winner) == tostring(match.contest.winner) then
		points = points + match.contest.points.win
	end

	for opponentIndex = 1, 2 do
		match['opponent' .. opponentIndex].extradata = json.stringify(match['opponent' .. opponentIndex].extradata)
		match['opponent' .. opponentIndex] = json.stringify(match['opponent' .. opponentIndex])
	end

	match.contest = nil

	Variables.varDefine('contestPoints', points)

	return match
end

return StarCraftMatchGroupInput
