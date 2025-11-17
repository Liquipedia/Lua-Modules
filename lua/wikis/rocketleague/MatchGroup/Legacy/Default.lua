---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

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
---@return string
function RocketLeagueMatchGroupLegacyDefault.run(frame)
	return RocketLeagueMatchGroupLegacyDefault(frame):build()
end

---@param frame Frame
---@return string
function RocketLeagueMatchGroupLegacyDefault.runGenerate(frame)
	frame.args.template = frame.args[1]
	frame.args.templateOld = frame.args[2]
	frame.args.type = frame.args.type or 'team'

	return RocketLeagueMatchGroupLegacyDefault(frame):generate()
end

return RocketLeagueMatchGroupLegacyDefault
