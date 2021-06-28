local FFA = {}

local json = require('Module:Json')
local Variables = require('Module:Variables')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Table = require('Module:Table')
local config = Lua.moduleExists('Module:Match/Config') and mw.loadData('Module:Match/Config') or {}
local WikiSpecific = require('Module:DevFlags').matchGroupDev
	and Lua.requireIfExists('Module:MatchGroup/Input/StarCraft/dev')
	or require('Module:MatchGroup/Input/StarCraft')

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20
local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local ALLOWED_STATUSES2 = { ['W'] = 'W', ['FF'] = 'FF', ['L'] = 'L', ['DQ'] = 'DQ', ['-'] = 'L' }
local MAX_NUM_OPPONENTS = 8
local MAX_NUM_VODGAMES = 9
local MODES2 = {
	['solo'] = '1',
	['duo'] = '2',
	['trio'] = '3',
	['quad'] = '4',
	['team'] = 'team',
	['literal'] = 'literal'
	}
local ALOWED_BG = {
	['up'] = 'up',
	['down'] = 'down',
	['stayup'] = 'stayup',
	['staydown'] = 'staydown',
	['stay'] = 'stay',
	['mid'] = 'stay',
	['drop'] = 'down',
	['proceed'] = 'up',
	}

function FFA.adjustData(match)
	local OppNumber = 0
	local noscore = match.noscore == 'true' or match.noscore == '1' or match.nopoints == 'true' or match.nopoints == '1'
	match.noscore = noscore

	--process pbg entries and set them into match.pbg (will get merged into extradata later on)
	match = FFA.get_pbg(match)

	--parse opponents + determine match mode + set initial stuff
	match.mode = ''
	match, OppNumber = FFA.OpponentInput(match, OppNumber, noscore)

	--indicate it is an FFA match
	match.mode = match.mode .. '_ffa'

	--main processing done here
	local subgroup = 0
	for i = 1, MAX_NUM_MAPS do
		if match['map' .. i] then
			--parse the stringified map arguments to be a table again
			match['map' .. i] = json.parseIfString(match['map' .. i])
		else
			break
		end
		if 	((match['map' .. i].opponent1placement or '') ~= '' or (match['map' .. i].placement1 or '') ~= '' or
				(match['map' .. i].points1 or '') ~= '' or (match['map' .. i].opponent1points or '') ~= '' or
				(match['map' .. i].score1 or '') ~= '' or (match['map' .. i].opponent1score or '') ~= '' or
				(match['map' .. i].map or '') ~= '') then
			match, subgroup = FFA.MapInput(match, i, subgroup, noscore, OppNumber)
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

	for i = 1, MAX_NUM_MAPS do
		if match['map' .. i] then
			--stringify maps
			match['map' .. i].participants = json.stringify(match['map' .. i].participants)
			match['map' .. i] = json.stringify(match['map' .. i])
		else
			break
		end
	end

	match = FFA.MatchWinnerProcessing(match, OppNumber, noscore)

	for opponentIndex = 1, OppNumber do
		--stringify player data
		for key, item in ipairs(match['opponent' .. opponentIndex].match2players) do
			match['opponent' .. opponentIndex].match2players[key].extradata = json.stringify(item.extradata)
		end
		match['opponent' .. opponentIndex].match2players = json.stringify(match['opponent' .. opponentIndex].match2players)
		--stringify opponent extradata
		match['opponent' .. opponentIndex].extradata = json.stringify(match['opponent' .. opponentIndex].extradata)
		--stringify opponents
		match['opponent' .. opponentIndex] = json.stringify(match['opponent' .. opponentIndex])
	end

	--Bracket Contest Handling
	if match.contest and tostring(match.contest.finished) == '1' then
		match = FFA.processContest(match, OppNumber)
	end

	return match
end

function FFA.get_pbg(match)
	local pbg = {}

	local advancecount = tonumber(match.advancecount or 0) or 0
	if advancecount > 0 then
		for index = 1, advancecount do
			pbg[index] = 'up'
		end
	end

	local index = 1
	while FFA.bgClean(match['pbg' .. index]) ~= '' do
		pbg[index] = FFA.bgClean(match['pbg' .. index])
		match['pbg' .. index] = nil
		index = index + 1
	end

	match.pbg = pbg

	return match
end

--helper function
function FFA.bgClean(pbg)
	local temp = pbg
	pbg = string.lower(pbg or '')
	if pbg == '' then
		return ''
	else
		pbg = ALOWED_BG[pbg]

		if not pbg then
			error('Bad bg/pbg entry "' .. temp .. '"')
		end

		return pbg
	end
end

--function to get extradata for storage
function FFA.getExtraData(match)
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
function FFA.placementSortFunction(table, key1, key2)
	local op1 = table[key1]
	local op2 = table[key2]
	return tonumber(op1) > tonumber(op2)
end

--[[

Match Winner, Walkover, Placement, Resulttype, Status functions

]]--
function FFA.MatchWinnerProcessing(match, OppNumber, noscore)
	local bestof = tonumber(match.firstto or '') or tonumber(match.bestof or '') or 9999
	match.bestof = bestof
	local walkover = match.walkover or ''
	local IndScore = {}
	for opponentIndex = 1, OppNumber do
		--determine opponent scores, status
		--determine MATCH winner, resulttype and walkover
		if walkover ~= '' then
			if Logic.isNumeric(walkover) then
				walkover = tonumber(walkover)
				if walkover == opponentIndex then
					match.winner = opponentIndex
					match.walkover = 'L'
					match['opponent' .. opponentIndex].status = 'W'
					IndScore[opponentIndex] = 9999
				elseif walkover == 0 then
					match.winner = 0
					match.walkover = 'L'
					match['opponent' .. opponentIndex].status = 'L'
					IndScore[opponentIndex] = -1
				else
					match['opponent' .. opponentIndex].status =
						ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score or '')] or 'L'
					IndScore[opponentIndex] = -1
				end
			elseif Table.includes(ALLOWED_STATUSES, string.upper(walkover)) then
				if tonumber(match.winner or 0) == opponentIndex then
					IndScore[opponentIndex] = 9999
					match['opponent' .. opponentIndex].status = 'W'
				else
					IndScore[opponentIndex] = -1
					match['opponent' .. opponentIndex].status = ALLOWED_STATUSES2[string.upper(walkover)] or 'L'
				end
			else
				match['opponent' .. opponentIndex].status =
					ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score or '')] or 'L'
				match.walkover = 'L'
				if ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score or '')] == 'W' then
					IndScore[opponentIndex] = 9999
				else
					IndScore[opponentIndex] = -1
				end
			end
			match['opponent' .. opponentIndex].score = -1
			match.finished = 'true'
			match.resulttype = 'default'
		elseif Logic.readBool(match.cancelled) then
			match.resulttype = 'np'
			match.finished = 'true'
			match['opponent' .. opponentIndex].score = -1
			IndScore[opponentIndex] = -1
		elseif ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score or '')] then
			if string.upper(match['opponent' .. opponentIndex].score) == 'W' then
				match.winner = opponentIndex
				match.resulttype = 'default'
				match.finished = 'true'
				match['opponent' .. opponentIndex].score = -1
				match['opponent' .. opponentIndex].status = 'W'
				IndScore[opponentIndex] = 9999
			else
				match.resulttype = 'default'
				match.finished = 'true'
				match.walkover = ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score)]
				match['opponent' .. opponentIndex].status =
					ALLOWED_STATUSES2[string.upper(match['opponent' .. opponentIndex].score)]
				match['opponent' .. opponentIndex].score = -1
				IndScore[opponentIndex] = -1
			end
		else
			match['opponent' .. opponentIndex].status = 'S'
			match['opponent' .. opponentIndex].score = tonumber(match['opponent' .. opponentIndex].score or '') or
				tonumber(match['opponent' .. opponentIndex].sumscore) or -1
			IndScore[opponentIndex] = match['opponent' .. opponentIndex].score
		end
	end

	match = FFA.MatchPlacements(match, OppNumber, noscore, IndScore)

	return match
end

--determine placements and winner (if not already set)
function FFA.MatchPlacements(match, OppNumber, noscore, IndScore)
	local counter = 0
	local temp = {}
	match.finished = (match.finished or '') ~= '' and match.finished ~= 'false' and match.finished ~= '0' and 'true' or nil

	if not noscore then
		for scoreIndex, score in Table.iter.spairs(IndScore, FFA.placementSortFunction) do
			counter = counter + 1
			if counter == 1 and (match.winner or '') == '' then
				if match.finished or score >= match.bestof then
					match.winner = scoreIndex
					match.finished = 'true'
					match['opponent' .. scoreIndex].placement = tonumber(match['opponent' .. scoreIndex].placement or '') or counter
					match['opponent' .. scoreIndex].extradata.advances = true
					match['opponent' .. scoreIndex].extradata.bg = match['opponent' .. scoreIndex].extradata.bg
						or match.pbg[match['opponent' .. scoreIndex].placement] or 'down'
					temp.place = counter
					temp.score = IndScore[scoreIndex]
				else
					break
				end
			elseif match.finished then
				if temp.score == score then
					match['opponent' .. scoreIndex].placement = tonumber(match['opponent' .. scoreIndex].placement or '') or temp.place
				else
					match['opponent' .. scoreIndex].placement = tonumber(match['opponent' .. scoreIndex].placement or '') or counter
					temp.place = counter
					temp.score = IndScore[scoreIndex]
				end
				match['opponent' .. scoreIndex].extradata.bg = match['opponent' .. scoreIndex].extradata.bg
						or match.pbg[match['opponent' .. scoreIndex].placement] or 'down'
				if match['opponent' .. scoreIndex].extradata.bg == 'up' then
					match['opponent' .. scoreIndex].extradata.advances = true
				end
			else
				break
			end
		end
	elseif tonumber(match.winner or '') then
		for oppIndex = 1, OppNumber do
			match['opponent' .. oppIndex].placement = tonumber(match['opponent' .. oppIndex].placement or '') or 99
			if match['opponent' .. oppIndex].placement == 99 and tonumber(match.winner) == oppIndex then
				match['opponent' .. oppIndex].placement = 1
			end
		end
	else
		for oppIndex = 1, OppNumber do
			match['opponent' .. oppIndex].placement = tonumber(match['opponent' .. oppIndex].placement or '') or 99
			if match['opponent' .. oppIndex].placement == 1 then
				match.winner = oppIndex
			end
		end
	end

	return match
end

--[[

OpponentInput functions

]]--
function FFA.OpponentInput(match, OppNumber, noscore)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		if not Logic.isEmpty(match['opponent' .. opponentIndex]) then
			OppNumber = opponentIndex
			--parse the stringified opponent arguments to be a table again
			match['opponent' .. opponentIndex] = json.parseIfString(match['opponent' .. opponentIndex])

			local bg = FFA.bgClean(match['opponent' .. opponentIndex].bg)
			match['opponent' .. opponentIndex].bg = nil
			local advances = match['opponent' .. opponentIndex].advance or ''
			if advances == '' then
				advances = match['opponent' .. opponentIndex].win or ''
				if advances == '' then
					advances = match['opponent' .. opponentIndex].advances or ''
				end
			end
			advances = advances ~= 'false' and advances ~= '' and advances ~= '0'

			--opponent processing (first part)
			--sort out extradata
			match['opponent' .. opponentIndex].extradata = {
				advantage = match['opponent' .. opponentIndex].advantage,
				score2 = match['opponent' .. opponentIndex].score2,
				isarchon = match['opponent' .. opponentIndex].isarchon,
				advances = advances,
				noscore = noscore,
				bg = bg
			}

			--set initial opponent sumscore
			match['opponent' .. opponentIndex].sumscore =
				tonumber(match['opponent' .. opponentIndex].extradata.advantage or '') or ''

			local temp_place = match['opponent' .. opponentIndex].placement
			--process input depending on type
			if match['opponent' .. opponentIndex]['type'] == 'solo' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessSoloOpponentInput(match['opponent' .. opponentIndex])
			elseif match['opponent' .. opponentIndex]['type'] == 'duo' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessDuoOpponentInput(match['opponent' .. opponentIndex])
			elseif match['opponent' .. opponentIndex]['type'] == 'trio' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessOpponentInput(match['opponent' .. opponentIndex], 3)
			elseif match['opponent' .. opponentIndex]['type'] == 'quad' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessOpponentInput(match['opponent' .. opponentIndex], 4)
			elseif match['opponent' .. opponentIndex]['type'] == 'team' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessTeamOpponentInput(match['opponent' .. opponentIndex], match.date)
			elseif match['opponent' .. opponentIndex]['type'] == 'literal' then
				match['opponent' .. opponentIndex] =
					WikiSpecific.ProcessLiteralOpponentInput(match['opponent' .. opponentIndex])
			else
				error('Unsupported Opponent Type')
			end

			match['opponent' .. opponentIndex].placement = temp_place

			--mark match as noQuery if it contains BYE/TBD/TBA/'' or Literal opponents
			local pltemp = string.lower(match['opponent' .. opponentIndex].name or '')
			if pltemp == '' or pltemp == 'tbd' or pltemp == 'tba' or pltemp == 'bye' or
					match['opponent' .. opponentIndex]['type'] == 'literal' then
				match.noQuery = 'true'
			end

			local mode = MODES2[match['opponent' .. opponentIndex]['type']]
			if mode == '2' and match['opponent' .. opponentIndex].extradata.isarchon == 'true' then
				mode = 'Archon'
			end

			match.mode = match.mode .. (opponentIndex ~= 1 and '_' or '') .. mode
		else
			break
		end
	end

	return match, OppNumber
end

--[[

MapInput functions

]]--
function FFA.MapInput(match, i, subgroup, noscore, OppNumber)
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

	--get participants data for the map + get map mode
	match['map' .. i] = WikiSpecific.ProcessPlayerMapData(match['map' .. i], match, OppNumber)

	--determine scores, resulttype, walkover and winner
	match['map' .. i] = FFA.MapScoreProcessing(match['map' .. i], OppNumber, noscore)

	--adjust sumscores if scores/points are used
	if not noscore then
		for j = 1, OppNumber do
			--set sumscore to 0 if it isn't a number
			if (match['opponent' .. j].sumscore or '') == '' then
				match['opponent' .. j].sumscore = 0
			end
			match['opponent' .. j].sumscore = match['opponent' .. j].sumscore + (tonumber(match['map' .. i].scores[j] or 0) or 0)
		end
	end

	--subgroup handling
	subgroup = tonumber(match['map' .. i].subgroup or '') or subgroup + 1

	return match, subgroup
end


function FFA.MapScoreProcessing(map, OppNumber, noscore)
	map.extradata = json.parseIfString(map.extradata)
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
			for scoreIndex, score in Table.iter.spairs(indexedScores, FFA.placementSortFunction) do
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

	map.extradata = json.stringify(map.extradata)

	return map
end






--[[

Bracket Contests function

]]--
function FFA.processContest(match, OppNumber)
	local points = tonumber(Variables.varDefault('contestPoints', 0)) or 0
	local score1 = {}
	local score2 = {}
	local Rscore1 = {}
	local Rscore2 = {}
	for opponentIndex = 1, OppNumber do
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

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		match['opponent' .. opponentIndex].extradata = json.stringify(match['opponent' .. opponentIndex].extradata)
		match['opponent' .. opponentIndex] = json.stringify(match['opponent' .. opponentIndex])
	end

	match.contest = nil

	Variables.varDefine('contestPoints', points)

	return match
end

return FFA
