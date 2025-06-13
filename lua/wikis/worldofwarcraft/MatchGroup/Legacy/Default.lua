---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MAX_NUMBER_OF_OPPONENTS = 2

---@class WorldofwarcraftMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'match$1$',
		['$parse$'] = 'match$1$'
	}
end


---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacyDefault:handleOpponents(isReset, match1params, match)
	local scoreKey = isReset and 'score2' or 'score'
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], scoreKey)
		if Logic.isEmpty(self.args[opp['$notEmpty$']]) then
			match['opponent' .. opponentIndex] = self:handleLiterals(match1params, opp, opponentIndex)
			return
		end

		opp['$notEmpty$'] = nil
		match['opponent' .. opponentIndex] = self:readOpponent(opp)
	end)
end

---@param match1params match1Keys
---@param opp table
---@param opponentIndex integer
---@return table?
function MatchGroupLegacyDefault:handleLiterals(match1params, opp, opponentIndex)
	opp.name = opp.name .. 'literal'
	if Logic.isEmpty(self.args[opp.name]) then return nil end

	local opponentArgs = self:readOpponent(opp)
	opponentArgs.type = Opponent.literal

	return opponentArgs
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
