---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class LoLMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
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
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
