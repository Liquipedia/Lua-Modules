---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchGroupLegacyDefault = {}

local Lua = require("Module:Lua")
local Logic = require("Module:Logic")
local String = require("Module:StringUtils")
local config = Lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

local roundData
function MatchGroupLegacyDefault.get(templateid, bracketType)
	local LowerHeader = {}
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)

	assert(type(matches) == "table")
	local bracketData = {}
	roundData = roundData or {}
	local lastround = 0
	for _, match in ipairs(matches) do
		bracketData, lastround, LowerHeader =
			MatchGroupLegacyDefault.getMatchMapping(match, bracketData, bracketType, LowerHeader)
	end

	-- add reference for map mappings
	bracketData["$$map"] = {
		["$notEmpty$"] = "map$1$",
		map = "map$1$",
		winner = "map$1$win",
		race1 = "map$1$p1race",
		race2 = "map$1$p2race"
	}

	for n=1,lastround do
		bracketData["R" .. n .. "M1header"] = "R" .. n
		if LowerHeader[n] then
			bracketData["R" .. n .. "M" .. LowerHeader[n] .. "header"] = "L" .. n
		end
	end

	return bracketData
end

local lastRound
function MatchGroupLegacyDefault.getMatchMapping(match, bracketData, bracketType, LowerHeader)
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

	if string.match(bd.header or '', '^!l') then
		LowerHeader[roundNum] = round.G
	end

	-- opponents
	local opponent1
	local finished1
	if Logic.isEmpty(bd.toupper) and not reset then
		-- RxDx
		opponent1 = {
		["type"] = "type",
		"R" .. round.R .. "D" .. round.D,
		flag = "R" .. round.R .. "D" .. round.D .. "flag",
		race = "R" .. round.R .. "D" .. round.D .. "race",
		score = "R" .. round.R .. "D" .. round.D .. "score",
		win = "R" .. round.R .. "D" .. round.D .. "win"
		}
		finished1 = "R" .. round.R .. "D" .. round.D .. "win"
		round.D = round.D + 1
	else
		-- RxWx
		opponent1 = {
		["type"] = "type",
		"R" .. round.R .. "W" .. round.W,
		flag = "R" .. round.R .. "W" .. round.W .. "flag",
		race = "R" .. round.R .. "W" .. round.W .. "race",
		score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
		win = "R" .. round.R .. "W" .. round.W .. "win"
		}
		finished1 = "R" .. round.R .. "W" .. round.W .. "win"
		round.W = round.W + 1
	end

	local opponent2
	local finished2
	if Logic.isEmpty(bd.tolower) and not reset then
		-- RxDx
		opponent2 = {
		["type"] = "type",
		"R" .. round.R .. "D" .. round.D,
		flag = "R" .. round.R .. "D" .. round.D .. "flag",
		race = "R" .. round.R .. "D" .. round.D .. "race",
		score = "R" .. round.R .. "D" .. round.D .. "score",
		win = "R" .. round.R .. "D" .. round.D .. "win"
		}
		finished2 = "R" .. round.R .. "D" .. round.D .. "win"
		round.D = round.D + 1
	else
		-- RxWx
		opponent2 = {
		["type"] = "type",
		"R" .. round.R .. "W" .. round.W,
		flag = "R" .. round.R .. "W" .. round.W .. "flag",
		race = "R" .. round.R .. "W" .. round.W .. "race",
		score = "R" .. round.R .. "W" .. round.W .. "score" .. (reset and "2" or ""),
		win = "R" .. round.R .. "W" .. round.W .. "win"
		}
		finished2 = "R" .. round.R .. "W" .. round.W .. "win"
		round.W = round.W + 1
	end

	opponent1["$notEmpty$"] = opponent1[1]
	opponent2["$notEmpty$"] = opponent2[1]

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

	return bracketData, round.R, LowerHeader
end

return MatchGroupLegacyDefault
