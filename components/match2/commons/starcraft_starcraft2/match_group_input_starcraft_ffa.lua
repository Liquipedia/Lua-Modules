---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local StarcraftMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local ALLOWED_STATUSES2 = { ['W'] = 'W', ['FF'] = 'FF', ['L'] = 'L', ['DQ'] = 'DQ', ['-'] = 'L' }
--local MAX_NUM_OPPONENTS = 8
local MAX_NUM_VODGAMES = 9
local MODES2 = {
	['solo'] = '1',
	['duo'] = '2',
	['trio'] = '3',
	['quad'] = '4',
	['team'] = 'team',
	['literal'] = 'literal'
}
local ALLOWED_BG = {
	['up'] = 'up',
	['down'] = 'down',
	['stayup'] = 'stayup',
	['staydown'] = 'staydown',
	['stay'] = 'stay',
	['mid'] = 'stay',
	['drop'] = 'down',
	['proceed'] = 'up',
}

local StarcraftFfaInput = {}

function StarcraftFfaInput.adjustData(match)
	local OppNumber = 0
	local noscore = match.noscore == 'true' or match.noscore == '1' or match.nopoints == 'true' or match.nopoints == '1'
	match.noscore = noscore

	--process pbg entries and set them into match.pbg (will get merged into extradata later on)
	match = StarcraftFfaInput.getPbg(match)

	--parse opponents + determine match mode + set initial stuff
	match.mode = ''
	match, OppNumber = StarcraftFfaInput.OpponentInput(match, OppNumber, noscore)

	--indicate it is an FFA match
	match.mode = match.mode .. '_ffa'

	--main processing done here
	local subgroup = 0
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map') do
		if ((map.opponent1placement or '') ~= '' or (map.placement1 or '') ~= '' or
				(map.points1 or '') ~= '' or (map.opponent1points or '') ~= '' or
				(map.score1 or '') ~= '' or (map.opponent1score or '') ~= '' or
				(map.map or '') ~= '') then
			match, subgroup = StarcraftFfaInput.MapInput(match, mapKey, subgroup, noscore, OppNumber)
		else
			match[mapKey] = nil
			break
		end
	end

	--apply vodgames
	for index = 1, MAX_NUM_VODGAMES do
		local vodgame = match['vodgame' .. index]
		if Logic.isNotEmpty(vodgame) and Logic.isNotEmpty(match['map' .. index]) then
			match['map' .. index].vod = match['map' .. index].vod or vodgame
		end
	end

	match = StarcraftFfaInput.MatchWinnerProcessing(match, OppNumber, noscore)

	--Bracket Contest Handling
	if match.contest and tostring(match.contest.finished) == '1' then
		match = StarcraftFfaInput.processContest(match, OppNumber)
	end

	return match
end

function StarcraftFfaInput.getPbg(match)
	local pbg = {}

	local advancecount = tonumber(match.advancecount or 0) or 0
	if advancecount > 0 then
		for index = 1, advancecount do
			pbg[index] = 'up'
		end
	end

	local index = 1
	while StarcraftFfaInput.bgClean(match['pbg' .. index]) ~= '' do
		pbg[index] = StarcraftFfaInput.bgClean(match['pbg' .. index])
		match['pbg' .. index] = nil
		index = index + 1
	end

	match.pbg = pbg

	return match
end

--helper function
function StarcraftFfaInput.bgClean(pbg)
	local temp = pbg
	pbg = string.lower(pbg or '')
	if pbg == '' then
		return ''
	else
		pbg = ALLOWED_BG[pbg]

		if not pbg then
			error('Bad bg/pbg entry "' .. temp .. '"')
		end

		return pbg
	end
end

--function to get extradata for storage
function StarcraftFfaInput.getExtraData(match)
	local extradata = {
		matchsection = Variables.varDefault('matchsection'),
		comment = match.comment,
		featured = match.featured,
		veto1by = (match.vetoplayer1 or '') ~= '' and match.vetoplayer1 or match.vetoopponent1,
		veto1 = match.veto1,
		veto2by = (match.vetoplayer2 or '') ~= '' and match.vetoplayer2 or match.vetoopponent2,
		veto2 = match.veto2,
		veto3by = (match.vetoplayer3 or '') ~= '' and match.vetoplayer3 or match.vetoopponent3,
		veto3 = match.veto3,
		veto4by = (match.vetoplayer4 or '') ~= '' and match.vetoplayer4 or match.vetoopponent4,
		veto4 = match.veto4,
		veto5by = (match.vetoplayer5 or '') ~= '' and match.vetoplayer5 or match.vetoopponent5,
		veto5 = match.veto5,
		veto6by = (match.vetoplayer6 or '') ~= '' and match.vetoplayer6 or match.vetoopponent6,
		veto6 = match.veto6,
		ffa = 'true',
		noscore = match.noscore,
		showplacement = match.showplacement,
	}

	--add the pbg stuff
	for key, item in pairs(match.pbg) do
		extradata['pbg' .. key] = item
	end
	match.pbg = nil

	return extradata
end

-- function to sort out placements
function StarcraftFfaInput.placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	return tonumber(op1) > tonumber(op2)
end

--[[

Match Winner, Walkover, Placement, Resulttype, Status functions

]]--
function StarcraftFfaInput.MatchWinnerProcessing(match, OppNumber, noscore)
	local bestof = tonumber(match.firstto or '') or tonumber(match.bestof or '') or 9999
	match.bestof = bestof
	local walkover = match.walkover or ''
	local IndScore = {}
	for opponentIndex = 1, OppNumber do
		local opponent = match['opponent' .. opponentIndex]
		--determine opponent scores, status
		--determine MATCH winner, resulttype and walkover
		if walkover ~= '' then
			if Logic.isNumeric(walkover) then
				walkover = tonumber(walkover)
				if walkover == opponentIndex then
					match.winner = opponentIndex
					match.walkover = 'L'
					opponent.status = 'W'
					IndScore[opponentIndex] = 9999
				elseif walkover == 0 then
					match.winner = 0
					match.walkover = 'L'
					opponent.status = 'L'
					IndScore[opponentIndex] = -1
				else
					opponent.status =
						ALLOWED_STATUSES2[string.upper(opponent.score or '')] or 'L'
					IndScore[opponentIndex] = -1
				end
			elseif Table.includes(ALLOWED_STATUSES, string.upper(walkover)) then
				if tonumber(match.winner or 0) == opponentIndex then
					IndScore[opponentIndex] = 9999
					opponent.status = 'W'
				else
					IndScore[opponentIndex] = -1
					opponent.status = ALLOWED_STATUSES2[string.upper(walkover)] or 'L'
				end
			else
				opponent.status =
					ALLOWED_STATUSES2[string.upper(opponent.score or '')] or 'L'
				match.walkover = 'L'
				if ALLOWED_STATUSES2[string.upper(opponent.score or '')] == 'W' then
					IndScore[opponentIndex] = 9999
				else
					IndScore[opponentIndex] = -1
				end
			end
			opponent.score = -1
			match.finished = 'true'
			match.resulttype = 'default'
		elseif Logic.readBool(match.cancelled) then
			match.resulttype = 'np'
			match.finished = 'true'
			opponent.score = -1
			IndScore[opponentIndex] = -1
		elseif ALLOWED_STATUSES2[string.upper(opponent.score or '')] then
			if string.upper(opponent.score) == 'W' then
				match.winner = opponentIndex
				match.resulttype = 'default'
				match.finished = 'true'
				opponent.score = -1
				opponent.status = 'W'
				IndScore[opponentIndex] = 9999
			else
				match.resulttype = 'default'
				match.finished = 'true'
				match.walkover = ALLOWED_STATUSES2[string.upper(opponent.score)]
				opponent.status =
					ALLOWED_STATUSES2[string.upper(opponent.score)]
				opponent.score = -1
				IndScore[opponentIndex] = -1
			end
		else
			opponent.status = 'S'
			opponent.score = tonumber(opponent.score or '')
				or tonumber(opponent.sumscore) or -1
			IndScore[opponentIndex] = opponent.score
		end
	end

	match = StarcraftFfaInput.MatchPlacements(match, OppNumber, noscore, IndScore)

	return match
end

--determine placements and winner (if not already set)
function StarcraftFfaInput.MatchPlacements(match, OppNumber, noscore, IndScore)
	local counter = 0
	local temp = {}
	match.finished = (match.finished or '') ~= '' and match.finished ~= 'false' and match.finished ~= '0' and 'true' or nil

	if not noscore then
		for scoreIndex, score in Table.iter.spairs(IndScore, StarcraftFfaInput.placementSortFunction) do
			local opponent = match['opponent' .. scoreIndex]
			counter = counter + 1
			if counter == 1 and (match.winner or '') == '' then
				if match.finished or score >= match.bestof then
					match.winner = scoreIndex
					match.finished = 'true'
					opponent.placement = tonumber(opponent.placement or '') or counter
					opponent.extradata.advances = true
					opponent.extradata.bg = opponent.extradata.bg
						or match.pbg[opponent.placement] or 'down'
					temp.place = counter
					temp.score = IndScore[scoreIndex]
				else
					break
				end
			elseif match.finished then
				if temp.score == score then
					opponent.placement = tonumber(opponent.placement or '') or temp.place
				else
					opponent.placement = tonumber(opponent.placement or '') or counter
					temp.place = counter
					temp.score = IndScore[scoreIndex]
				end
				opponent.extradata.bg = opponent.extradata.bg
					or match.pbg[opponent.placement] or 'down'
				if opponent.extradata.bg == 'up' then
					opponent.extradata.advances = true
				end
			else
				break
			end
		end
	elseif tonumber(match.winner or '') then
		for oppIndex = 1, OppNumber do
			local opponent = match['opponent' .. oppIndex]
			opponent.placement = tonumber(opponent.placement or '') or 99
			if opponent.placement == 99 and tonumber(match.winner) == oppIndex then
				opponent.placement = 1
			end
		end
	else
		for oppIndex = 1, OppNumber do
			local opponent = match['opponent' .. oppIndex]
			opponent.placement = tonumber(opponent.placement or '') or 99
			if opponent.placement == 1 then
				match.winner = oppIndex
			end
		end
	end

	return match
end

--[[

OpponentInput functions

]]--
function StarcraftFfaInput.OpponentInput(match, OppNumber, noscore)
	for opponentKey, opponent in Table.iter.pairsByPrefix(match, 'opponent') do
		local opponentIndex = tonumber(opponentKey:match('(%d+)$'))
		OppNumber = opponentIndex

		local bg = StarcraftFfaInput.bgClean(opponent.bg)
		opponent.bg = nil
		local advances = opponent.advance or ''
		if advances == '' then
			advances = opponent.win or ''
			if advances == '' then
				advances = opponent.advances or ''
			end
		end
		advances = advances ~= 'false' and advances ~= '' and advances ~= '0'

		--opponent processing (first part)
		--sort out extradata
		opponent.extradata = {
			advances = advances,
			advantage = opponent.advantage,
			bg = bg,
			isarchon = opponent.isarchon,
			noscore = noscore,
			score2 = opponent.score2,
		}

		--set initial opponent sumscore
		opponent.sumscore =
			tonumber(opponent.extradata.advantage or '') or ''

		local temp_place = opponent.placement
		--process input depending on type
		if opponent.type == 'solo' then
			opponent = StarcraftMatchGroupInput.ProcessSoloOpponentInput(opponent)
		elseif opponent.type == 'duo' then
			opponent = StarcraftMatchGroupInput.ProcessDuoOpponentInput(opponent)
		elseif opponent.type == 'trio' then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 3)
		elseif opponent.type == 'quad' then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 4)
		elseif opponent.type == 'team' then
			opponent = StarcraftMatchGroupInput.ProcessTeamOpponentInput(opponent, match.date)
		elseif opponent.type == 'literal' then
			opponent = StarcraftMatchGroupInput.ProcessLiteralOpponentInput(opponent)
		else
			error('Unsupported Opponent Type')
		end
		match[opponentKey] = opponent

		opponent.placement = temp_place

		--mark match as noQuery if it contains BYE/TBD/TBA/'' or Literal opponents
		local pltemp = string.lower(opponent.name or '')
		if pltemp == '' or pltemp == 'tbd' or pltemp == 'tba' or pltemp == 'bye' or
				opponent.type == 'literal' then
			match.noQuery = 'true'
		end

		local mode = MODES2[opponent.type]
		if mode == '2' and opponent.extradata.isarchon == 'true' then
			mode = 'Archon'
		end

		match.mode = match.mode .. (opponentIndex ~= 1 and '_' or '') .. mode
	end

	return match, OppNumber
end

--[[

MapInput functions

]]--
function StarcraftFfaInput.MapInput(match, mapKey, subgroup, noscore, OppNumber)
	local map = match[mapKey]

	--redirect maps
	if map.map ~= 'TBD' then
		map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')
	end

	--set initial extradata for maps
	map.extradata = {
		comment = map.comment or '',
		header = map.header or '',
		isSubMatch = 'false',
		noQuery = match.noQuery,
	}

	--inherit stuff from match data
	map.type = match.type
	map.liquipediatier = match.liquipediatier
	map.liquipediatiertype = match.liquipediatiertype
	map.game = match.game
	map.date = match.date

	--get participants data for the map + get map mode
	map = StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, OppNumber)

	--determine scores, resulttype, walkover and winner
	map = StarcraftFfaInput.MapScoreProcessing(map, OppNumber, noscore)

	--adjust sumscores if scores/points are used
	if not noscore then
		for j = 1, OppNumber do
			--set sumscore to 0 if it isn't a number
			if (match['opponent' .. j].sumscore or '') == '' then
				match['opponent' .. j].sumscore = 0
			end
			match['opponent' .. j].sumscore = match['opponent' .. j].sumscore + (tonumber(map.scores[j] or 0) or 0)
		end
	end

	--subgroup handling
	subgroup = tonumber(map.subgroup) or subgroup + 1

	match[mapKey] = map

	return match, subgroup
end


function StarcraftFfaInput.MapScoreProcessing(map, OppNumber, noscore)
	map.scores = {}
	local indexedScores = {}
	local hasScoreSet = false
	--read scores
	if not noscore then
		for scoreIndex = 1, OppNumber do
			local score =	(map['score' .. scoreIndex] or '') ~= '' and map['score' .. scoreIndex] or
							(map['points' .. scoreIndex] or '') ~= '' and map['points' .. scoreIndex] or
							(map['opponent' .. scoreIndex .. 'points'] or '') ~= '' and map['opponent' .. scoreIndex .. 'points'] or
							(map['opponent' .. scoreIndex .. 'score'] or '') ~= '' and map['opponent' .. scoreIndex .. 'score'] or ''
			score = ALLOWED_STATUSES2[score] or tonumber(score) or 0
			indexedScores[scoreIndex] = score
			if not Logic.isNumeric(score) then
				map.resulttype = 'default'
				if (map.walkover or '') == '' or map.walkover == 'L' then
					if score == 'DQ' then
						map.walkover = 'DQ'
					elseif score == 'FF' then
						map.walkover = 'FF'
					else
						map.walkover = 'L'
					end
				end
				if score == 'W' then
					indexedScores[scoreIndex] = 9999
				else
					indexedScores[scoreIndex] = -1
				end
			end

			--check if any score is not 0, i.e. a score has been actually entered
			if score ~= 0 then
				hasScoreSet = true
			end

			map.scores[scoreIndex] = score
		end

		--determine map winner and placements from scores if not set manually
		if hasScoreSet then
			local counter = 0
			local temp = {}
			for scoreIndex, score in Table.iter.spairs(indexedScores, StarcraftFfaInput.placementSortFunction) do
				counter = counter + 1
				if counter == 1 and (map.winner or '') == '' then
					map.winner = scoreIndex
					map.extradata['placement' .. scoreIndex] = tonumber(map['placement' .. scoreIndex] or '') or
						tonumber(map['opponent' .. scoreIndex .. 'placement'] or '') or counter
					temp.place = counter
					temp.score = indexedScores[scoreIndex]
				elseif temp.score == score then
					map.extradata['placement' .. scoreIndex] = tonumber(map['placement' .. scoreIndex] or '') or
						tonumber(map['opponent' .. scoreIndex .. 'placement'] or '') or temp.place
				else
					map.extradata['placement' .. scoreIndex] = tonumber(map['placement' .. scoreIndex] or '') or
						tonumber(map['opponent' .. scoreIndex .. 'placement'] or '') or counter
					temp.place = counter
					temp.score = indexedScores[scoreIndex]
				end
			end
		end
	elseif tonumber(map.winner or '') then
		for oppIndex = 1, OppNumber do
			map.extradata['placement' .. oppIndex] = tonumber(map['placement' .. oppIndex] or '') or
				tonumber(map['opponent' .. oppIndex .. 'placement'] or '') or 99
			if map.extradata['placement' .. oppIndex] == 99 and tonumber(map.winner) == oppIndex then
				map.extradata['placement' .. oppIndex] = 1
			end
		end
	else
		for oppIndex = 1, OppNumber do
			map.extradata['placement' .. oppIndex] = tonumber(map['placement' .. oppIndex] or '') or
				tonumber(map['opponent' .. oppIndex .. 'placement'] or '') or 99
			if map.extradata['placement' .. oppIndex] == 1 then
				map.winner = oppIndex
			end
		end
	end

	return map
end






--[[

Bracket Contests function

]]--
function StarcraftFfaInput.processContest(match, OppNumber)
	local points = tonumber(Variables.varDefault('contestPoints', 0)) or 0
	local score1 = {}
	local score2 = {}
	local Rscore1 = {}
	local Rscore2 = {}
	for opponentIndex = 1, OppNumber do
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
	else
		local diff = score1[1] - Rscore1[1]
		local hasSameDiff = true
		for i = 2, OppNumber do
			if score1[i] - Rscore1[i] - diff ~= 0 then
				hasSameDiff = false
				break
			end
		end
		if hasSameDiff then
			points = points + match.contest.points.diff
		elseif tostring(match.winner) == tostring(match.contest.winner) then
			points = points + match.contest.points.win
		end
	end

	match.contest = nil

	Variables.varDefine('contestPoints', points)

	return match
end

return StarcraftFfaInput
