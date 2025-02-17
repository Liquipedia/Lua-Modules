---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class CallofdutyMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'map$1$win',
		map = 'map$1$',
		winner = 'map$1$win',
		mode = 'map$1$type',
		vod = 'vodgame$1$',
		score1 = 'map$1$score1',
		score2 = 'map$1$score2',
	}
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault