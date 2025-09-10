---
-- @Liquipedia
-- wiki=fighters
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2

---@class FightersMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param template string
---@param bracketType string?
---@return match2mapping
function MatchGroupLegacyDefault.get(template, bracketType)
	return MatchGroupLegacy.getAlt(template)
end

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacyDefault:getOpponent(prefix, scoreKey)
	return {
		['$notEmpty$'] = prefix,
		score = prefix .. scoreKey,
		name = prefix ,
		displayname = prefix .. 'display',
		flag = prefix .. 'flag',
	}
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
	mw.logObject(match)
end

---@param isReset boolean
---@param prefix string
---@return table
function MatchGroupLegacyDefault:getDetails(isReset, prefix)
	local details = MatchGroupLegacy.getDetails(self, false, prefix)

	Table.iter.forEachPair(self.args, function (key)
		if not tonumber(key) and String.startsWith(key, prefix) then
			if String.contains(key, 'p1char') or String.contains(key, 'p2char') then
				details[key:gsub(prefix, '')] = Json.stringify({self.args[key]})
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
	}
end

---@param isReset boolean?
---@param match table
function MatchGroupLegacyDefault:handleOtherMatchParams(isReset, match)
	mw.logObject(match)
	match.winner = Table.extract(match, 'win')
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
