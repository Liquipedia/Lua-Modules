local p = {}

local String = require("Module:StringUtils")
local Logic = require("Module:Logic")

local MAX_NUM_MAPS = 20

local roundData
function p.get(templateid, bracketType)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)
	assert(type(matches) == "table")
	local bracketData = {}
	roundData = roundData or {}
	for _, match in ipairs(matches) do
		bracketData = p._getMatchMapping(match, bracketData, bracketType)
	end
	-- add reference for map mappings
	bracketData["$$map"] = {
		["$notEmpty$"] = "map$1$",
		ot = "ot$1$",
		otlength = "otlength$1$",
		map = "map$1$",
		score1 = "map$1$t1score",
		score2 = "map$1$t2score",
		winner = "map$1$win"
	}

	return bracketData
end

local lastRound
function p._getMatchMapping(match, bracketData, bracketType)
	local id = String.split(match.match2id, "_")[2] or match.match2id
	id = id:gsub("0*([1-9])", "%1"):gsub("%-", "")
	local bd = match.match2bracketdata

	local roundNum
	local round
	local reset = false
	if id == "RxMTP" then
		round = lastRound
	elseif id == "RxMBR" then
		round = lastRound
		round.G = round.G - 2
		round.W = round.W - 2
		round.D = round.D - 2
		reset = true
	else
		roundNum = id:match("R%d*"):gsub("R", "")
		roundNum = tonumber(roundNum)
		round = roundData[roundNum] or { R = roundNum, G = 0, D = 1, W = 1 }
	end
	round.G = round.G + 1

	-- opponents
	local opponent1
	local finished1
	local finished2
	if Logic.isEmpty(bd.toupper) and not reset then
		-- RxDx
		if bracketType == "team" then
			opponent1 = {
				["type"] = "type",
				template = "R" .. round.R .. "D" .. round.D .. "team",
				score = "R" .. round.R .. "D" .. round.D .. "score",
				["$notEmpty$"] = "R" .. round.R .. "D" .. round.D .. "team"
			}
		else
			opponent1 = {
				["type"] = "type",
				template = "R" .. round.R .. "D" .. round.D .. "team",
				score = "R" .. round.R .. "D" .. round.D .. "score",
				["$notEmpty$"] = "R" .. round.R .. "D" .. round.D,
				name = "R" .. round.R .. "D" .. round.D,
				displayname = "R" .. round.R .. "D" .. round.D,
				flag = "R" .. round.R .. "D" .. round.D .. 'flag'
			}
		end
		finished1 = "R" .. round.R .. "D" .. round.D .. "win"
		round.D = round.D + 1
	else
		-- RxWx
		if bracketType == "team" then
			opponent1 = {
				["type"] = "type",
				template = "R" .. round.R .. "W" .. round.W .. "team",
				score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
				["$notEmpty$"] = "R" .. round.R .. "W" .. round.W .. "team"
			}
		else
			opponent1 = {
				["type"] = "type",
				template = "R" .. round.R .. "W" .. round.W .. "team",
				score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
				["$notEmpty$"] = "R" .. round.R .. "W" .. round.W,
				name = "R" .. round.R .. "W" .. round.W,
				displayname = "R" .. round.R .. "W" .. round.W,
				flag = "R" .. round.R .. "W" .. round.W .. 'flag'
			}
		end
		finished1 = "R" .. round.R .. "W" .. round.W .. "win"
		round.W = round.W + 1
	end

	local opponent2
	if Logic.isEmpty(bd.tolower) and not reset then
		-- RxDx
		if bracketType == "team" then
			opponent2 = {
				["type"] = "type",
				template = "R" .. round.R .. "D" .. round.D .. "team",
				score = "R" .. round.R .. "D" .. round.D .. "score",
				["$notEmpty$"] = "R" .. round.R .. "D" .. round.D .. "team"
			}
		else
			opponent2 = {
				["type"] = "type",
				template = "R" .. round.R .. "D" .. round.D .. "team",
				score = "R" .. round.R .. "D" .. round.D .. "score",
				["$notEmpty$"] = "R" .. round.R .. "D" .. round.D,
				name = "R" .. round.R .. "D" .. round.D,
				displayname = "R" .. round.R .. "D" .. round.D,
				flag = "R" .. round.R .. "D" .. round.D .. 'flag'
			}
		end
		finished2 = "R" .. round.R .. "D" .. round.D .. "win"
		round.D = round.D + 1
	else
		-- RxWx
		if bracketType == "team" then
			opponent2 = {
				["type"] = "type",
				template = "R" .. round.R .. "W" .. round.W .. "team",
				score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
				["$notEmpty$"] = "R" .. round.R .. "W" .. round.W .. "team"
			}
		else
			opponent2 = {
				["type"] = "type",
				template = "R" .. round.R .. "W" .. round.W .. "team",
				score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
				["$notEmpty$"] = "R" .. round.R .. "W" .. round.W,
				name = "R" .. round.R .. "W" .. round.W,
				displayname = "R" .. round.R .. "W" .. round.W,
				flag = "R" .. round.R .. "W" .. round.W .. 'flag'
			}
		end
		finished2 = "R" .. round.R .. "W" .. round.W .. "win"
		round.W = round.W + 1
	end

	match = {
		opponent1 = opponent1,
		opponent2 = opponent2,
		finished = finished1 .. "|" .. finished2,
		-- reference to variables that shall be flattened
		["$flatten$"] = { "R" .. round.R .. "G" .. round.G .. "details" }
	}

	for mapIndex = 1, MAX_NUM_MAPS do
		match["map" .. mapIndex] = {
			["$ref$"] = "map",
			["$1$"] = mapIndex
		}
	end

	bracketData[id] = match
	lastRound = round
	roundData[round.R] = round

	return bracketData
end

--[[
custom mappings are used to overwrite the default mappings
in the cases where the default mappings do not fit the
parameter format of the old bracket
]]--

--this can be used for custom mappings too
function p.addMaps(match)
	for mapIndex = 1, MAX_NUM_MAPS do
		match["map" .. mapIndex] = {
			["$ref$"] = "map",
			["$1$"] = mapIndex
		}
	end
	return match
end

--this is for custom mappings
function p.matchMappingFromCustom(data, bracketType)
	--[[
	data has the form {
		opp1, -- e.g. R1D1
		opp2, -- e.g. R1D20
		details, -- e.g. R1G5details
	}
	]]--
	local mapping = {
		["$flatten$"] = { data.details },
		["finished"] = data.opp1 .. "win|" .. data.opp2 .. "win",
		["opponent1"] = {
			["type"] = "type",
			["$notEmpty$"] = data.opp1 ..
				(bracketType == "team" and "team" or ""),
			template = data.opp1 .. "team",
			score = data.opp1 .. "score",
			name = bracketType ~= "team" and data.opp1 or nil,
			displayname = bracketType ~= "team" and data.opp1 or nil,
			flag = bracketType ~= "team" and data.opp1 or nil,
			win = data.opp1 .. "win",
			},
		["opponent2"] = {
			["type"] = "type",
			["$notEmpty$"] = data.opp2 ..
				(bracketType == "team" and "team" or ""),
			template = data.opp2 .. "team",
			score = data.opp2 .. "score",
			name = bracketType ~= "team" and data.opp2 or nil,
			displayname = bracketType ~= "team" and data.opp2 or nil,
			flag = bracketType ~= "team" and data.opp2 or nil,
			win = data.opp2 .. "win",
			},
	}
	mapping = p.addMaps(mapping)

	return mapping
end

--this is for custom mappings for Reset finals matches
--it switches score2 into the place of score
--and sets flatten to nil
function p.matchResetMappingFromCustom(mapping)
	local mappingReset = mw.clone(mapping)
	mappingReset.opponent1.score = mapping.opponent1.score .. "2"
	mappingReset.opponent2.score = mapping.opponent2.score .. "2"
	mappingReset["$flatten$"] = nil
	return mappingReset
end

return p
