---
-- @Liquipedia
-- wiki=valorant
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

return MatchGroupLegacyDefault
