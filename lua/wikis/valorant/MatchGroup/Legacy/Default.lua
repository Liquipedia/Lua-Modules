---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_PLAYERS = 5

---@class ValorantMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	local map = {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		t1firstside = 'map$1$t1firstside',
		t1firstsideot = 'map$1$t1firstsideot',
		finished = 'map$1$finished',
		length = 'map$1$length',
		vod = 'map$1$vod',
		winner = 'map$1$winner'
	}

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (oppIndex)
		map['score' .. oppIndex] = 'map$1$score' .. oppIndex
		--side score
		map['t' .. oppIndex .. 'atk'] = 'map$1$t' .. oppIndex .. 'atk'
		map['t' .. oppIndex .. 'def'] = 'map$1$t' .. oppIndex .. 'def'
		--ot side score
		map['t' .. oppIndex .. 'otatk'] = 'map$1$t' .. oppIndex .. 'otatk'
		map['t' .. oppIndex .. 'otdef'] = 'map$1$t' .. oppIndex .. 'otdef'

		Array.forEach(Array.range(1, MAX_NUMBER_OF_PLAYERS), function (pIndex)
			local key = 't' .. oppIndex .. 'p' .. pIndex
			map[key] = 'map$1$' .. key
		end)
	end)

	return map
end

---@param frame Frame
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

---@param isReset boolean
---@param match table
function MatchGroupLegacyDefault:handleOtherMatchParams(isReset, match)
	local opp1score, opp2score = (match.opponent1 or {}).score, (match.opponent2 or {}).score
	-- Maps are >Bo9, while >Bo5 in legacy matches are non existent
	-- Let's assume that if the sum of the scores is less than 10, it's a match, otherwise it's a map
	if (tonumber(opp1score) or 0) + (tonumber(opp2score) or 0) < 10 then
		return
	end

	(match.opponent1 or {}).score = nil
	(match.opponent2 or {}).score = nil
	match.map1 = match.map1 or {
		map = 'Unknown',
		finished = true,
		score1 = opp1score,
		score2 = opp2score,
	}
end

return MatchGroupLegacyDefault
