---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class HearthstoneMatchGroupLegacyDefault: MatchGroupLegacy
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
---@param prefix string
---@return table
function MatchGroupLegacyDefault:getDetails(isReset, prefix)
	local details = MatchGroupLegacy.getDetails(self, false, prefix)

	Table.iter.forEachPair(self.args, function (key)
		if not tonumber(key) and String.startsWith(key, prefix) then
			details[key:gsub(prefix, '')] = self.args[key]
		end
	end)

	return details
end

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'win$1$',
		winner = 'win$1$',
		o1c1 = 'p1class$1$',
		o2c1 = 'p2class$1$',
		vod = 'vodgame$1$'
	}
end

---@param isReset boolean?
---@param match table
function MatchGroupLegacyDefault:handleOtherMatchParams(isReset, match)
	match.winner = Table.extract(match, 'win')
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
