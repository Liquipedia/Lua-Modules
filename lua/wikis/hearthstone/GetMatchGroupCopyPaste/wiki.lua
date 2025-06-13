---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')
local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

---WikiSpecific Code for MatchList and Bracket Code Generators
---@class HearthstoneMatchCopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if opponents > 2 then
		return WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	else
		return WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	end
end

---returns the Code for a standard Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)

	local lines = Array.extend(
		'{{Match|bestof=' .. bestof,
		INDENT .. '|date=',
		INDENT .. '|twitch=|vod=',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. WikiCopyPaste._getStandardMap(mode, opponents)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

--subfunction used to generate code for the Map template, depending on the type of opponent
---@param mode string
---@param opponents integer
---@return string
function WikiCopyPaste._getStandardMap(mode, opponents)
	if mode == Opponent.team then
		return '={{Map|o1p1=|o2p1=|o1c1=|o2c1=|winner=}}'
	elseif mode == Opponent.literal then
		return '={{Map|winner=}}'
	end

	local parts = Array.extend({'={{Map'},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return table.concat(Array.map(Array.range(1, Opponent.partySize(mode) --[[@as integer]]), function(playerIndex)
				return '|o' .. opponentIndex .. 'c' .. playerIndex .. '='
			end))
		end),
		'|winner=}}'
	)

	return table.concat(parts)
end

---returns the Code for a FFA Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend(
		'{{Match|finished=',
		INDENT .. '|p1=7.1 |p2=6 |p3=5 |p4=4 |p5=3 |p6=2 |p7=1 |p8=0',
		INDENT .. '|twitch= |youtube=',
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|date=|finished=|vod=}}'
		end),
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getFfaOpponent(mode, bestof)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
