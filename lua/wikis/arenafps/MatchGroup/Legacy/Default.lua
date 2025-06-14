---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')


---@class ArenafpsMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		finished = 'map$1$finished',
		winner = 'map$1$winner',
		score1 = 'map$1$score1',
		score2 = 'map$1$score2',
		vod = 'vodgame$1$'
	}
end

---@param frame Frame
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
