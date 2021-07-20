local p = {}

local String = require("Module:StringUtils")
local Logic = require("Module:Logic")

local MAX_NUM_MAPS = 1 --20 (changed for shorter logs)

local roundData
function p.get(templateid, bracketType)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)
	assert(type(matches) == "table")
	local bracketData = {}
	roundData = roundData or {}
	for index, match in ipairs(matches) do
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
	local matchNum
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
				--match2players = {
						name = "R" .. round.R .. "D" .. round.D,
						displayname = "R" .. round.R .. "D" .. round.D,
						flag = "R" .. round.R .. "D" .. round.D .. 'flag'
				--	}
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
				--match2players = {
						name = "R" .. round.R .. "W" .. round.W,
						displayname = "R" .. round.R .. "W" .. round.W,
						flag = "R" .. round.R .. "W" .. round.W .. 'flag'
				--	}
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
				--match2players = {
						name = "R" .. round.R .. "D" .. round.D,
						displayname = "R" .. round.R .. "D" .. round.D,
						flag = "R" .. round.R .. "D" .. round.D .. 'flag'
				--	}
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
				--match2players = {
						name = "R" .. round.R .. "W" .. round.W,
						displayname = "R" .. round.R .. "W" .. round.W,
						flag = "R" .. round.R .. "W" .. round.W .. 'flag'
				--	}
			}
		end
		finished2 = "R" .. round.R .. "W" .. round.W .. "win"
		round.W = round.W + 1
	end

	local match = {
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

return p
