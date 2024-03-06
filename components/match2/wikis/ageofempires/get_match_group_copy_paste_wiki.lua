---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---WikiSpecific Code for MatchList and Bracket Code Generators
---@class AgeOfEmpiresMatchCopyPaste: Match2CopyPasteBase
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
	local maps
	if mode == Opponent.solo then
		maps = Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|winner=|civs1=|civs2=}}'
		end)
	else
		maps = Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|winner=|players1=|civs1=|players2=|civs2=}}'
		end)
	end

	local lines = Array.extend(
		'{{Match',
		INDENT .. '|date=',
		INDENT .. '|bestof=' .. bestof,
		INDENT .. '|twitch=|vod=',
		INDENT .. '|civdraft=|mapdraft=',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode)
		end),
		maps,
		'}}'
	)

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@return string
function WikiCopyPaste._getOpponent(mode)
	if mode == Opponent.solo then
		return '{{SoloOpponent|}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

return WikiCopyPaste
