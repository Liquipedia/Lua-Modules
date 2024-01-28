---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchGroupLegacyDefault = {}

local String = require('Module:StringUtils')
local Logic = require('Module:Logic')

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
		winner = 'map$1$winner'
	}

	return bracketData
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

	-- opponents
	local opponent1
	local finished1
	local finished2
	if Logic.isEmpty(bd.toupper) and not reset then
		-- RxDx
		if bracketType == 'team' then
			opponent1 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'D' .. round.D .. 'team',
				score = 'R' .. round.R .. 'D' .. round.D .. 'score',
				['$notEmpty$'] = 'R' .. round.R .. 'D' .. round.D .. 'team'
			}
		else
			opponent1 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'D' .. round.D .. 'team',
				score = 'R' .. round.R .. 'D' .. round.D .. 'score',
				['$notEmpty$'] = 'R' .. round.R .. 'D' .. round.D,
				name = 'R' .. round.R .. 'D' .. round.D,
				displayname = 'R' .. round.R .. 'D' .. round.D .. 'display',
				flag = 'R' .. round.R .. 'D' .. round.D .. 'flag'
			}
		end
		finished1 = 'R' .. round.R .. 'D' .. round.D .. 'win'
		round.D = round.D + 1
	else
		-- RxWx
		if bracketType == 'team' then
			opponent1 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'W' .. round.W .. 'team',
				score = 'R' .. round.R .. 'W' .. round.W .. 'score' .. (reset and '2' or ''),
				['$notEmpty$'] = 'R' .. round.R .. 'W' .. round.W .. 'team'
			}
		else
			opponent1 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'W' .. round.W .. 'team',
				score = 'R' .. round.R .. 'W' .. round.W .. 'score' .. (reset and '2' or ''),
				['$notEmpty$'] = 'R' .. round.R .. 'W' .. round.W,
				name = 'R' .. round.R .. 'W' .. round.W,
				displayname = 'R' .. round.R .. 'W' .. round.W .. 'display',
				flag = 'R' .. round.R .. 'W' .. round.W .. 'flag'
			}
		end
		finished1 = 'R' .. round.R .. 'W' .. round.W .. 'win'
		round.W = round.W + 1
	end

	local opponent2
	if Logic.isEmpty(bd.tolower) and not reset then
		-- RxDx
		if bracketType == 'team' then
			opponent2 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'D' .. round.D .. 'team',
				score = 'R' .. round.R .. 'D' .. round.D .. 'score',
				['$notEmpty$'] = 'R' .. round.R .. 'D' .. round.D .. 'team'
			}
		else
			opponent2 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'D' .. round.D .. 'team',
				score = 'R' .. round.R .. 'D' .. round.D .. 'score',
				['$notEmpty$'] = 'R' .. round.R .. 'D' .. round.D,
				name = 'R' .. round.R .. 'D' .. round.D,
				displayname = 'R' .. round.R .. 'D' .. round.D .. 'display',
				flag = 'R' .. round.R .. 'D' .. round.D .. 'flag'
			}
		end
		finished2 = 'R' .. round.R .. 'D' .. round.D .. 'win'
		round.D = round.D + 1
	else
		-- RxWx
		if bracketType == 'team' then
			opponent2 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'W' .. round.W .. 'team',
				score = 'R' .. round.R .. 'W' .. round.W .. 'score' .. (reset and '2' or ''),
				['$notEmpty$'] = 'R' .. round.R .. 'W' .. round.W .. 'team'
			}
		else
			opponent2 = {
				['type'] = 'type',
				template = 'R' .. round.R .. 'W' .. round.W .. 'team',
				score = 'R' .. round.R .. 'W' .. round.W .. 'score' .. (reset and '2' or ''),
				['$notEmpty$'] = 'R' .. round.R .. 'W' .. round.W,
				name = 'R' .. round.R .. 'W' .. round.W,
				displayname = 'R' .. round.R .. 'W' .. round.W .. 'display',
				flag = 'R' .. round.R .. 'W' .. round.W .. 'flag'
			}
		end
		finished2 = 'R' .. round.R .. 'W' .. round.W .. 'win'
		round.W = round.W + 1
	end

	match = {
		opponent1 = opponent1,
		opponent2 = opponent2,
		finished = finished1 .. '|' .. finished2,
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

	return MatchGroupLegacyDefault.addMaps{
		['$flatten$'] = { data.details .. 'details' },
		['finished'] = data.opp1 .. 'win|' .. data.opp2 .. 'win',
		['opponent1'] = {
			['type'] = 'type',
			['$notEmpty$'] = data.opp1 .. (bracketType == 'team' and 'team' or ''),
			template = data.opp1 .. 'team',
			score = data.opp1 .. 'score',
			name = bracketType ~= 'team' and data.opp1 or nil,
			displayname = bracketType ~= 'team' and (data.opp1 .. 'display') or nil,
			flag = bracketType ~= 'team' and data.opp1 or nil,
			win = data.opp1 .. 'win',
		},
		['opponent2'] = {
			['type'] = 'type',
			['$notEmpty$'] = data.opp2 .. (bracketType == 'team' and 'team' or ''),
			template = data.opp2 .. 'team',
			score = data.opp2 .. 'score',
			name = bracketType ~= 'team' and data.opp2 or nil,
			displayname = bracketType ~= 'team' and (data.opp2 .. 'display') or nil,
			flag = bracketType ~= 'team' and data.opp2 or nil,
			win = data.opp2 .. 'win',
		},
	}
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
