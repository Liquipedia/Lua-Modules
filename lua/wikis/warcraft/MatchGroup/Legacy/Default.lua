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

local MAX_NUM_PLAYERS_IN_TEAM_SUBMATCH = 4
local TBD = 'TBD'
local SKIP = 'skip'

---@class WarcraftMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacyDefault:getOpponent(prefix, scoreKey)
	return {
		['$notEmpty$'] = self.bracketType == 'team' and (prefix .. 'team') or prefix,
		name = prefix,
		template = prefix .. 'team',
		flag = prefix .. 'flag',
		race = prefix .. 'race',
		link = prefix .. 'link',
		score = prefix .. scoreKey,
		win = prefix .. 'win'
	}
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacyDefault:handleOpponents(isReset, match1params, match)
	local scoreKey = isReset and 'score2' or 'score'
	Array.forEach(Array.range(1, 2), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], scoreKey)
		local notEmptyPrefix = opp['$notEmpty$']

		if Logic.isNotEmpty(self.args[notEmptyPrefix]) then
			match['opponent' .. opponentIndex] = self:readOpponent(opp)
			return
		elseif self.bracketType ~= 'solo' then
			return
		elseif Logic.isEmpty(self.args[notEmptyPrefix .. 'flag']) and Logic.isEmpty(self.args[notEmptyPrefix .. 'race']) then
			return
		end

		match['opponent' .. opponentIndex] = self:readOpponent(opp)
	end)
end

---@return table
function MatchGroupLegacyDefault:getMap()
	local map = {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		winner = 'map$1$win',
		race1 = 'map$1$p1race',
		race2 = 'map$1$p2race',
		score1 = 'map$1$p1score',
		score2 = 'map$1$p2score',
		heroes1 = 'map$1$p1heroes',
		heroes2 = 'map$1$p2heroes',
		t1p1heroesNoCheck = 'map$1$p1heroesNoCheck',
		t2p1heroesNoCheck = 'map$1$p2heroesNoCheck',
		vod = 'vodgame$1$',
		subgroup = 'map$1$subgroup',
		walkover = 'map$1$walkover',
		finished = 'map$1$finished',
	}

	if self.bracketType == 'team' then
		Array.forEach(Array.range(1, MAX_NUM_PLAYERS_IN_TEAM_SUBMATCH), function (playerIndex)
			map['t1p' .. playerIndex] = 'map$1$t1p' .. playerIndex
			map['t2p' .. playerIndex] = 'map$1$t2p' .. playerIndex
			--races
			map['t1p' .. playerIndex .. 'race'] = 'map$1$t1p' .. playerIndex .. 'race'
			map['t2p' .. playerIndex .. 'race'] = 'map$1$t2p' .. playerIndex .. 'race'
			--heroes
			map['t1p' .. playerIndex .. 'heroes'] = 'map$1$t1p' .. playerIndex .. 'heroes'
			map['t2p' .. playerIndex .. 'heroes'] = 'map$1$t2p' .. playerIndex .. 'heroes'
		end)
	end

	return map
end

---@param opponentData table
---@return table
function MatchGroupLegacyDefault:readOpponent(opponentData)
	opponentData['$notEmpty$'] = nil
	local opponent = self:_copyAndReplace(opponentData, self.args)
	if self.bracketType == 'solo' then
		opponent[1] = opponent.name or TBD
		opponent.name = nil
	end
	opponent.type = self.bracketType

	-- `score=skip` can have different meaning
	--- walkover with it being input for winner
	--- walkover with it being input for loser
	--- not played with only 1 opponent in the match (usually it being input on the player that was in the match)
	--- not played with it being input for any of the 2 players
	--- double walkover with it being input for any of the 2 players
	-- in the old brackets it did not have any display at all, hence nil it here
	if string.lower(opponent.score or '') == SKIP then
		opponent.score = nil
	end

	return opponent
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
