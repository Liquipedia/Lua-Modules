---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local StarcraftMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft/deprecated')
local Opponent = Lua.import('Module:Opponent')

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local ALLOWED_STATUSES2 = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local MAX_NUM_VODGAMES = 9
local MODES2 = {
	solo = '1',
	duo = '2',
	trio = '3',
	quad = '4',
	team = 'team',
	literal = 'literal'
}
local ALLOWED_BG = {
	up = 'up',
	down = 'down',
	stayup = 'stayup',
	staydown = 'staydown',
	stay = 'stay',
	mid = 'stay',
	drop = 'down',
	proceed = 'up',
}
local _TBD_STRINGS = {
	'definitions',
	'tbd'
}
local _BESTOF_DUMMY = 9999
local _DEFAULT_WIN_SCORE_VALUE = 9999
local _PLACEMENT_DUMMY = 99

local StarcraftFfaInput = {}

function StarcraftFfaInput.adjustData(match)
	local noscore = Logic.readBool(match.noscore) or Logic.readBool(match.nopoints)
	match.noscore = noscore

	--process pbg entries and set them into match.pbg (will get merged into extradata later on)
	match = StarcraftFfaInput._getPbg(match)

	--parse opponents + determine match mode + set initial stuff
	match.mode = ''
	local numberOfOpponents
	match, numberOfOpponents = StarcraftFfaInput._opponentInput(match, noscore)

	--indicate it is an FFA match
	match.mode = match.mode .. 'ffa'

	--main processing done here
	local subgroup = 0
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map') do
		if
			Logic.isNotEmpty(map.opponent1placement) or Logic.isNotEmpty(map.placement1)
			or Logic.isNotEmpty(map.points1) or Logic.isNotEmpty(map.opponent1points)
			or Logic.isNotEmpty(map.score1) or Logic.isNotEmpty(map.opponent1score)
			or String.isNotEmpty(map.map)
		then
			match, subgroup = StarcraftFfaInput._mapInput(match, mapKey, subgroup, noscore, numberOfOpponents)
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

	match = StarcraftFfaInput._matchWinnerProcessing(match, numberOfOpponents, noscore)

	return match
end

function StarcraftFfaInput._getPbg(match)
	local pbg = {}

	local advancecount = tonumber(match.advancecount or 0) or 0
	if advancecount > 0 then
		for index = 1, advancecount do
			pbg[index] = 'up'
		end
	end

	local index = 1
	while StarcraftFfaInput._bgClean(match['pbg' .. index]) ~= '' do
		pbg[index] = StarcraftFfaInput._bgClean(match['pbg' .. index])
		match['pbg' .. index] = nil
		index = index + 1
	end

	match.pbg = pbg

	return match
end

--helper function
function StarcraftFfaInput._bgClean(pbg)
	local pbgInput = pbg
	pbg = string.lower(pbg or '')
	if pbg == '' then
		return ''
	else
		pbg = ALLOWED_BG[pbg]

		if not pbg then
			error('Bad bg/pbg entry "' .. pbgInput .. '"')
		end

		return pbg
	end
end

--function to get extradata for storage
function StarcraftFfaInput.getExtraData(match)
	local extradata = {
		featured = match.featured,
		veto1by = String.nilIfEmpty(match.vetoplayer1) or match.vetoopponent1,
		veto1 = match.veto1,
		veto2by = String.nilIfEmpty(match.vetoplayer2) or match.vetoopponent2,
		veto2 = match.veto2,
		veto3by = String.nilIfEmpty(match.vetoplayer3) or match.vetoopponent3,
		veto3 = match.veto3,
		veto4by = String.nilIfEmpty(match.vetoplayer4) or match.vetoopponent4,
		veto4 = match.veto4,
		veto5by = String.nilIfEmpty(match.vetoplayer5) or match.vetoopponent5,
		veto5 = match.veto5,
		veto6by = String.nilIfEmpty(match.vetoplayer6) or match.vetoopponent6,
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
function StarcraftFfaInput._placementSortFunction(tbl, key1, key2)
	local op1 = tbl[key1]
	local op2 = tbl[key2]
	return tonumber(op1) > tonumber(op2)
end

--[[

Match Winner, Walkover, Placement, Resulttype, Status functions

]]--
function StarcraftFfaInput._matchWinnerProcessing(match, numberOfOpponents, noscore)
	local bestof = tonumber(match.firstto) or tonumber(match.bestof) or _BESTOF_DUMMY
	match.bestof = bestof
	local walkover = match.walkover
	local IndScore = {}
	for opponentIndex = 1, numberOfOpponents do
		local opponent = match['opponent' .. opponentIndex]
		--determine opponent scores, status
		--determine MATCH winner, resulttype and walkover
		if walkover then
			if Logic.isNumeric(walkover) then
				local numericWalkover = tonumber(walkover)
				if numericWalkover == opponentIndex then
					match.winner = opponentIndex
					match.walkover = 'L'
					opponent.status = 'W'
					IndScore[opponentIndex] = _DEFAULT_WIN_SCORE_VALUE
				elseif numericWalkover == 0 then
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
					IndScore[opponentIndex] = _DEFAULT_WIN_SCORE_VALUE
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
					IndScore[opponentIndex] = _DEFAULT_WIN_SCORE_VALUE
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
				IndScore[opponentIndex] = _DEFAULT_WIN_SCORE_VALUE
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

	match = StarcraftFfaInput._matchPlacements(match, numberOfOpponents, noscore, IndScore)

	return match
end

--determine placements and winner (if not already set)
function StarcraftFfaInput._matchPlacements(match, numberOfOpponents, noscore, IndScore)
	local counter = 0
	local temp = {}
	match.finished = Logic.isNotEmpty(match.finished)
		and match.finished ~= 'false' and match.finished ~= '0'
		and 'true' or nil

	if not noscore then
		for scoreIndex, score in Table.iter.spairs(IndScore, StarcraftFfaInput._placementSortFunction) do
			local opponent = match['opponent' .. scoreIndex]
			counter = counter + 1
			if counter == 1 and Logic.isEmpty(match.winner) then
				if match.finished or score >= match.bestof then
					match.winner = scoreIndex
					match.finished = 'true'
					opponent.placement = tonumber(opponent.placement or '') or counter
					opponent.extradata.advances = true
					opponent.extradata.bg = String.nilIfEmpty(opponent.extradata.bg)
						or match.pbg[opponent.placement]
						or 'down'
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
				opponent.extradata.bg = String.nilIfEmpty(opponent.extradata.bg)
					or match.pbg[opponent.placement]
					or 'down'
				if opponent.extradata.bg == 'up' then
					opponent.extradata.advances = true
				end
			else
				break
			end
		end
	elseif tonumber(match.winner or '') then
		for oppIndex = 1, numberOfOpponents do
			local opponent = match['opponent' .. oppIndex]
			opponent.placement = tonumber(opponent.placement or '') or _PLACEMENT_DUMMY
			if opponent.placement == _PLACEMENT_DUMMY and tonumber(match.winner) == oppIndex then
				opponent.placement = 1
			end
		end
	else
		for oppIndex = 1, numberOfOpponents do
			local opponent = match['opponent' .. oppIndex]
			opponent.placement = tonumber(opponent.placement or '') or _PLACEMENT_DUMMY
			if opponent.placement == 1 then
				match.winner = oppIndex
			end
		end
	end

	if match.finished then
		for oppIndex = 1, numberOfOpponents do
			local opponent = match['opponent' .. oppIndex]
			opponent.extradata.bg = String.nilIfEmpty(opponent.extradata.bg)
				or match.pbg[opponent.placement]
				or 'down'
		end
	end

	return match
end

--[[

OpponentInput functions

]]--
function StarcraftFfaInput._opponentInput(match, noscore)
	local numberOfOpponents
	for opponentKey, opponent, opponentIndex in Table.iter.pairsByPrefix(match, 'opponent') do
		numberOfOpponents = opponentIndex

		-- Convert byes to literals
		if string.lower(opponent.template or '') == 'bye' or string.lower(opponent.name or '') == 'bye' then
			opponent = {type = Opponent.literal, name = 'BYE'}
		end

		local bg = StarcraftFfaInput._bgClean(opponent.bg)
		opponent.bg = nil
		local advances = opponent.advance
		if String.isEmpty(advances) then
			advances = opponent.win
			if String.isEmpty(advances) then
				advances = opponent.advances
			end
		end
		advances = Logic.isNotEmpty(advances) and advances ~= 'false' and advances ~= '0'

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

		-- read placement input for the opponent to overwrite
		-- the one set by the default opponent input processing
		-- as that sets placements assuming it is a non ffa match
		local inputPlace = opponent.placement
		--process input depending on type
		if opponent.type == Opponent.solo then
			opponent = StarcraftMatchGroupInput.ProcessSoloOpponentInput(opponent)
		elseif opponent.type == Opponent.duo then
			opponent = StarcraftMatchGroupInput.ProcessDuoOpponentInput(opponent)
		elseif opponent.type == Opponent.trio then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 3)
		elseif opponent.type == Opponent.quad then
			opponent = StarcraftMatchGroupInput.ProcessOpponentInput(opponent, 4)
		elseif opponent.type == Opponent.team then
			opponent = StarcraftMatchGroupInput.ProcessTeamOpponentInput(opponent, match.date)
		elseif opponent.type == Opponent.literal then
			opponent = StarcraftMatchGroupInput.ProcessLiteralOpponentInput(opponent)
		else
			error('Unsupported Opponent Type')
		end
		match[opponentKey] = opponent

		opponent.placement = inputPlace

		--mark match as noQuery if it contains TBD or Literal opponents
		local opponentName = string.lower(opponent.name or '')
		local playerName = string.lower(((opponent.match2players or {})[1] or {}).name or '')
		if
			opponent.type == Opponent.literal or
			Table.includes(_TBD_STRINGS, opponentName) or
			Table.includes(_TBD_STRINGS, playerName)
		then
			match.noQuery = 'true'
		end

		local mode = MODES2[opponent.type]
		if mode == '2' and opponent.extradata.isarchon == 'true' then
			mode = 'Archon'
		end

		match.mode = match.mode .. mode .. '_'
	end

	return match, numberOfOpponents
end

--[[

MapInput functions

]]--
function StarcraftFfaInput._mapInput(match, mapKey, subgroup, noscore, numberOfOpponents)
	local map = match[mapKey]

	--redirect maps
	if map.map ~= 'TBD' then
		map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')
	end

	--set initial extradata for maps
	map.extradata = {
		comment = map.comment or '',
		header = map.header or '',
		noQuery = match.noQuery,
	}

	--inherit stuff from match data
	map.type = match.type
	map.liquipediatier = match.liquipediatier
	map.liquipediatiertype = match.liquipediatiertype
	map.game = match.game
	map.date = match.date

	--get participants data for the map + get map mode
	map = StarcraftMatchGroupInput.ProcessPlayerMapData(map, match, numberOfOpponents)

	--determine scores, resulttype, walkover and winner
	map = StarcraftFfaInput._mapScoreProcessing(map, numberOfOpponents, noscore)

	--adjust sumscores if scores/points are used
	if not noscore then
		for j = 1, numberOfOpponents do
			--set sumscore to 0 if it isn't a number
			if String.isEmpty(match['opponent' .. j].sumscore) then
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


function StarcraftFfaInput._mapScoreProcessing(map, numberOfOpponents, noscore)
	map.scores = {}
	local indexedScores = {}
	local hasScoreSet = false
	--read scores
	if not noscore then
		for scoreIndex = 1, numberOfOpponents do
			local score = String.nilIfEmpty(map['score' .. scoreIndex])
				or String.nilIfEmpty(map['points' .. scoreIndex])
				or ''
			score = ALLOWED_STATUSES2[score] or tonumber(score) or 0
			indexedScores[scoreIndex] = score
			if not Logic.isNumeric(score) then
				map.resulttype = 'default'
				if String.isEmpty(map.walkover) or map.walkover == 'L' then
					if score == 'DQ' then
						map.walkover = 'DQ'
					elseif score == 'FF' then
						map.walkover = 'FF'
					else
						map.walkover = 'L'
					end
				end
				if score == 'W' then
					indexedScores[scoreIndex] = _DEFAULT_WIN_SCORE_VALUE
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
			for scoreIndex, score in Table.iter.spairs(indexedScores, StarcraftFfaInput._placementSortFunction) do
				counter = counter + 1
				if counter == 1 and Logic.isEmpty(map.winner) then
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
		for oppIndex = 1, numberOfOpponents do
			map.extradata['placement' .. oppIndex] = tonumber(map['placement' .. oppIndex] or '') or
				tonumber(map['opponent' .. oppIndex .. 'placement'] or '') or _PLACEMENT_DUMMY
			if map.extradata['placement' .. oppIndex] == _PLACEMENT_DUMMY and tonumber(map.winner) == oppIndex then
				map.extradata['placement' .. oppIndex] = 1
			end
		end
	else
		for oppIndex = 1, numberOfOpponents do
			map.extradata['placement' .. oppIndex] = tonumber(map['placement' .. oppIndex] or '') or
				tonumber(map['opponent' .. oppIndex .. 'placement'] or '') or _PLACEMENT_DUMMY
			if map.extradata['placement' .. oppIndex] == 1 then
				map.winner = oppIndex
			end
		end
	end

	return map
end

return StarcraftFfaInput
