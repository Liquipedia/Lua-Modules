---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2

---@class BrawlhallaMatchGroupLegacyDefault: MatchGroupLegacy
---@operator call(Frame): BrawlhallaMatchGroupLegacyDefault
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param template string
---@param bracketType string?
---@return match2mapping
function MatchGroupLegacyDefault.get(template, bracketType)
	return MatchGroupLegacy.getAlt(template, bracketType)
end

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacyDefault:getOpponent(prefix, scoreKey)
	if self.bracketType == Opponent.duo then
		local matchPrefix = prefix:sub(1, prefix:len() - 2)
		local opponentIndex = prefix:sub(-1, -1)
		local opponentPrefix = matchPrefix .. 't' .. opponentIndex
		return {
			['$notEmpty$'] = opponentPrefix .. 'p' .. 1,
			p1 = opponentPrefix .. 'p' .. 1,
			p1flag = opponentPrefix .. 'p' .. '1flag',
			p2 = opponentPrefix .. 'p' .. 2,
			p2flag = opponentPrefix .. 'p' .. '2flag',
			win = prefix .. 'win',
		}
	end
	return MatchGroupLegacy.getOpponent(self, prefix, scoreKey)
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacyDefault:handleOpponents(isReset, match1params, match)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], 'score')
		if isReset then
			opp.score = match1params['details'] .. (self.bracketType == Opponent.solo and 'p' or 't')
					.. opponentIndex .. 'score'
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
			details[key:gsub(prefix, '')] = Table.extract(self.args, key)
		end
	end)

	return details
end

---@return table
function MatchGroupLegacyDefault:getMap()
	if self.bracketType == Opponent.solo then
		return {
			['$notEmpty$'] = 'win$1$',
			winner = 'win$1$',
			char1 = 'p1char$1$',
			char2 = 'p2char$1$',
			map = 'stage$1$',
			vod = 'vodgame$1$'
		}
	elseif self.bracketType == Opponent.duo then
		return {
			['$notEmpty$'] = 'win$1$',
			winner = 'win$1$',
			o1char1 = 't1p1char$1$',
			o1char2 = 't1p2char$1$',
			o2char1 = 't2p1char$1$',
			o2char2 = 't2p2char$1$',
			map = 'stage$1$',
			vod = 'vodgame$1$'
		}
	end
	return {
		['$notEmpty$'] = 'win$1$',
		winner = 'win$1$',
		map = 'stage$1$',
		vod = 'vodgame$1$'
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
