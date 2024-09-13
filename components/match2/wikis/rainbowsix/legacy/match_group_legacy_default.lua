---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class RainbowsixMatchGroupLegacyDefault: MatchGroupLegacy
---@field _base MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		finished = 'map$1$finished',
		score1 = 'map$1$score1',
		score2 = 'map$1$score2',
		t1ban1 = 'map$1$t1ban1',
		t1ban2 = 'map$1$t1ban2',
		t2ban1 = 'map$1$t2ban1',
		t2ban2 = 'map$1$t2ban2',
		t1firstside = 'map$1$t1firstside',
		t1firstsideot = 'map$1$o1t1firstside',
		t1atk = 'map$1$t1atk',
		t1def = 'map$1$t1def',
		t2atk = 'map$1$t2atk',
		t2def = 'map$1$t2def',
		t1otatk = 'map$1$o1t1atk',
		t1otdef = 'map$1$o1t1def',
		t2otatk = 'map$1$o1t2atk',
		t2otdef = 'map$1$o1t2def',
		vod = 'vod$1$',
		winner = 'map$1$win'
	}
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

---@param match2key string
---@param match1params match1Keys
function MatchGroupLegacyDefault:getMatch(match2key, match1params)
	local match = self._base.getMatch(self, match2key, match1params)
	if not match then
		return nil
	end
	if not match.map1 then
		match.map1 = {
			map = 'Unknown',
			finished = true,
			score1 = (match.opponent1 or {}).score,
			score2 = (match.opponent2 or {}).score,
		}
	end
	(match.opponent1 or {}).score = nil
	(match.opponent2 or {}).score = nil
	return match
end

return MatchGroupLegacyDefault
