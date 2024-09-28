---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

---@class AgeofEmpiresMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	local map = {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		mode = 'map$1$mode',
		winner = 'map$1$win',
		civs1 = 'map$1$p1civ',
		civs2 = 'map$1$p2civ',
		vod = 'vodgame$1$',
		date = 'date$1$',
	}

	if self.bracketType == 'team' then
		Table.mergeInto(map, {
			players1 = 'map$1$t1players',
			players2 = 'map$1$t2players',
			civs1 = 'map$1$t1civs',
			civs2 = 'map$1$t2civs',
		})
	end

	return map
end

---@param details table
---@param mapIndex number
---@return table?
function MatchGroupLegacyDefault:handleMap(details, mapIndex)
	local blueprint = self:_getMap(mapIndex)
	if Logic.isEmpty(details[blueprint['$notEmpty$']]) then
		return nil
	end

	blueprint = Table.copy(blueprint)
	blueprint['$notEmpty$'] = nil

	return self:_copyAndReplace(blueprint, details, true)
end

---@param frame Frame
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
