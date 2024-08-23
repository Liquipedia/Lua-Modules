---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class RocketLeagueMatchGroupLegacyDefault: MatchGroupLegacy
local RocketLeagueMatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function RocketLeagueMatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'map$1$',
		ot = 'ot$1$',
		otlength = 'otlength$1$',
		map = 'map$1$',
		score1 = 'map$1$t1score',
		score2 = 'map$1$t2score',
		winner = 'map$1$win',
		t1goals = 'map$1$t1goals',
		t2goals = 'map$1$t2goals'
	}
end

---@param frame Frame
function RocketLeagueMatchGroupLegacyDefault.run(frame)
	return RocketLeagueMatchGroupLegacyDefault(frame):build()
end

return RocketLeagueMatchGroupLegacyDefault
