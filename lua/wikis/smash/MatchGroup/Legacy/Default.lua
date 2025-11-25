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
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2

---@class SmashMatchGroupLegacyDefault: MatchGroupLegacy
---@operator call(Frame): SmashMatchGroupLegacyDefault
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
			---@cast key string
			if String.contains(key, 'p1char') or String.contains(key, 'p2char') then
				local playerPrefix = key:gsub(prefix, ''):sub(1, 2)
				details[key:gsub(prefix, '')] = Json.stringify{
					self.args[key] .. ',' .. (self.args[
						prefix .. playerPrefix .. 'stock' .. key:gsub(prefix .. playerPrefix, ''):sub(5)
					] or '')
				}
			else
				details[key:gsub(prefix, '')] = self.args[key]
			end
		end
	end)
	mw.logObject(details)
	return details
end

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'win$1$',
		winner = 'win$1$',
		map = 'stage$1$',
		o1c1 = 'p1char$1$',
		o2c1 = 'p2char$1$',
		vod = 'vodgame$1$',
	}
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.runGenerate(frame)
	frame.args.template = frame.args[1]
	frame.args.templateOld = frame.args[2]
	frame.args.type = frame.args.type or Opponent.solo

	return MatchGroupLegacyDefault(frame):generate()
end

return MatchGroupLegacyDefault
