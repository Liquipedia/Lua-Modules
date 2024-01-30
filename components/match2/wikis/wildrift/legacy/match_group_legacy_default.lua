---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchGroupLegacyDefault = {}

local String = require('Module:StringUtils')
local Logic = require('Module:Logic')

local MAX_NUM_OPPONENTS = 2
local MAX_NUM_MAPS = 9

local roundData
function MatchGroupLegacyDefault.get(templateid, bracketType)
	local lowerHeader = {}
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)

	assert(type(matches) == 'table')
	local bracketData = {}
	roundData = roundData or {}
	local lastRound = 0
	for _, match in ipairs(matches) do
		bracketData, lastRound, lowerHeader = MatchGroupLegacyDefault._getMatchMapping(match, bracketData,
																						bracketType, lowerHeader)
	end

	for n = 1, lastRound do
		bracketData['R' .. n .. 'M1header'] = 'R' .. n
		if lowerHeader[n] then
			bracketData['R' .. n .. 'M' .. lowerHeader[n] .. 'header'] = 'L' .. n
		end
	end

	-- add reference for map mappings
	bracketData['$$map'] = {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		team1side = 'map$1$team1side',
		t1c1 = 'map$1$t1c1',
		t1c2 = 'map$1$t1c2',
		t1c3 = 'map$1$t1c3',
		t1c4 = 'map$1$t1c4',
		t1c5 = 'map$1$t1c5',
		t1b1 = 'map$1$t1b1',
		t1b2 = 'map$1$t1b2',
		t1b3 = 'map$1$t1b3',
		t1b4 = 'map$1$t1b4',
		t1b5 = 'map$1$t1b5',
		team2side = 'map$1$team2side',
		t2c1 = 'map$1$t2c1',
		t2c2 = 'map$1$t2c2',
		t2c3 = 'map$1$t2c3',
		t2c4 = 'map$1$t2c4',
		t2c5 = 'map$1$t2c5',
		t2b1 = 'map$1$t2b1',
		t2b2 = 'map$1$t2b2',
		t2b3 = 'map$1$t2b3',
		t2b4 = 'map$1$t2b4',
		t2b5 = 'map$1$t2b5',
		length = 'map$1$length',
		winner = 'map$1$winner',
		vod = 'map$1$vod'
	}

	return bracketData
end

function MatchGroupLegacyDefault._readOpponent(prefix, scoreKey, bracketType)
	return {
		['type'] = 'type',
		template = prefix .. 'team',
		score = prefix .. scoreKey,
		name = prefix,
		displayname = prefix .. 'display',
		flag = prefix .. 'flag',
		win = prefix .. 'win',
		['$notEmpty$'] = bracketType == 'team' and (prefix .. 'team') or prefix
	}
end

--the following variable gets mutaded by each p._getMatchMapping
--it is needed as a basis for the next call
local _lastRound
function MatchGroupLegacyDefault._getMatchMapping(match, bracketData, bracketType, lowerHeader)
	local id = String.split(match.match2id, '_')[2] or match.match2id
	--remove 0's and dashes from the match param
	--e.g. R01-M001 --> R1M1
	id = id:gsub('0*([1-9])', '%1'):gsub('%-', '')
	local bd = match.match2bracketdata

	local roundNum
	local round
	local reset = false
	if id == 'RxMTP' then
		round = _lastRound
	elseif id == 'RxMBR' then
		round = _lastRound
		round.G = round.G - 2
		round.W = round.W - 2
		round.D = round.D - 2
		reset = true
	else
		roundNum = id:match('R%d*'):gsub('R', '')
		roundNum = tonumber(roundNum)
		round = roundData[roundNum] or { R = roundNum, G = 0, D = 1, W = 1 }
	end
	round.G = round.G + 1

	--if bd.header starts with '!l'
	if string.match(bd.header or '', '^!l') then
		lowerHeader[roundNum or ''] = round.G
	end

	local opponents = {}
	local finished = {}
	local scoreKey = (reset and 'score2' or 'score')
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local prefix
		if not reset and
			(Logic.isEmpty(bd.toupper) and opponentIndex == 1 or
			Logic.isEmpty(bd.tolower) and opponentIndex == 2) then

			prefix = 'R' .. round.R .. 'D' .. round.D
			round.D = round.D + 1
		else
			prefix = 'R' .. round.R .. 'W' .. round.W
			round.W = round.W + 1
		end

		opponents[opponentIndex] = MatchGroupLegacyDefault._readOpponent(prefix, scoreKey, bracketType)
		finished[opponentIndex] = prefix .. 'win'
	end

	match = {
		opponent1 = opponents[1],
		opponent2 = opponents[2],
		finished = finished[1] .. '|' .. finished[2],
		-- reference to variables that shall be flattened
		['$flatten$'] = { 'R' .. round.R .. 'G' .. round.G .. 'details' }
	}

	bracketData[id] = MatchGroupLegacyDefault.addMaps(match)
	_lastRound = round
	roundData[round.R] = round

	return bracketData, round.R, lowerHeader
end

--[[
custom mappings are used to overwrite the default mappings
in the cases where the default mappings do not fit the
parameter format of the old bracket
]]--

--this can be used for custom mappings too
function MatchGroupLegacyDefault.addMaps(match)
	for mapIndex = 1, MAX_NUM_MAPS do
		match['map' .. mapIndex] = {
			['$ref$'] = 'map',
			['$1$'] = mapIndex
		}
	end
	return match
end

--this is for custom mappings
function MatchGroupLegacyDefault.matchMappingFromCustom(data, bracketType)
	--[[
	data has the form {
		opp1, -- e.g. R1D1
		opp2, -- e.g. R1D20
		details, -- e.g. R1G5
	}
	]]--
	bracketType = bracketType or 'team'

	local mapping = {
		['$flatten$'] = {data.details .. 'details'},
		['finished'] = data.opp1 .. 'win|' .. data.opp2 .. 'win',
		opponent1 = MatchGroupLegacyDefault._readOpponent(data.opp1, 'score', bracketType),
		opponent2 =  MatchGroupLegacyDefault._readOpponent(data.opp2, 'score', bracketType),
	}
	mapping = MatchGroupLegacyDefault.addMaps(mapping)

	return mapping
end

--this is for custom mappings for Reset finals matches
--it switches score2 into the place of score
--and sets flatten to nil
function MatchGroupLegacyDefault.matchResetMappingFromCustom(mapping)
	local mappingReset = mw.clone(mapping)
	mappingReset.opponent1.score = mapping.opponent1.score .. '2'
	mappingReset.opponent2.score = mapping.opponent2.score .. '2'
	mappingReset['$flatten$'] = nil
	return mappingReset
end

return MatchGroupLegacyDefault
