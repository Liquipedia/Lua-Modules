---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2

---@class FightersMatchGroupLegacyDefault: MatchGroupLegacy
---@operator call(Frame): FightersMatchGroupLegacyDefault
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param template string
---@param bracketType string?
---@return match2mapping
function MatchGroupLegacyDefault.get(template, bracketType)
	return MatchGroupLegacy.getAlt(template, bracketType)
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacyDefault:handleOpponents(isReset, match1params, match)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], 'score')
		if isReset then
			opp.score = match1params['details'] .. 'p' .. opponentIndex .. 'score'
		end
		if Logic.isEmpty(self.args[opp['$notEmpty$']]) then return end

		opp['$notEmpty$'] = nil
		match['opponent' .. opponentIndex] = self:readOpponent(opp)
	end)
end

---@param isReset boolean
---@param prefix string
---@return table
function MatchGroupLegacyDefault:getDetails(isReset, prefix)
	local details = MatchGroupLegacy.getDetails(self, false, prefix)

	Table.iter.forEachPair(self.args, function (key)
		if not tonumber(key) and String.startsWith(key, prefix) then
			if String.contains(key, 'p1char') or String.contains(key, 'p2char') then
				details[key:gsub(prefix, '')] = Json.stringify(Array.parseCommaSeparatedString(self.args[key]))
			else
				details[key:gsub(prefix, '')] = self.args[key]
			end
		end
	end)

	return details
end

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'win$1$',
		winner = 'win$1$',
		score1 = 'p1score$1$',
		score2 = 'p2score$1$',
		o1p1 = 'p1char$1$',
		o2p1 = 'p2char$1$',
		vod = 'vodgame$1$'
	}
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
