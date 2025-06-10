---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class RainbowsixMatchGroupLegacyDefault: MatchGroupLegacy
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

---@param isReset boolean
---@param match table
function MatchGroupLegacyDefault:handleOtherMatchParams(isReset, match)
	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		map.bantype = 'siege'
	end
	local opp1score, opp2score = (match.opponent1 or {}).score, (match.opponent2 or {}).score
	-- Legacy maps are Bo10 or Bo12, while >Bo5 in legacy matches are non existent
	-- Let's assume that if the sum of the scores is less than 6, it's a match, otherwise it's a map
	if (tonumber(opp1score) or 0) + (tonumber(opp2score) or 0) < 6 then
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
