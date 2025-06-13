---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---@class RocketleagueMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---@param mapIndex integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex)
	return INDENT .. '|map' .. mapIndex .. '=' .. table.concat({
		'{{Map',
		INDENT .. INDENT .. '|map=',
		INDENT .. INDENT .. '|score1=|score2=',
		INDENT .. INDENT .. '|ot=|otlength=',
		INDENT .. INDENT .. '|vod=',
		INDENT .. '}}'
	}, '\n')
end

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend(
		'{{Match',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode)
		end),
		Array.map(Array.range(1, bestof), WikiCopyPaste._getMapCode),
		INDENT .. '|finished=',
		INDENT .. '|date=',
		'}}',
		''
	)

	return table.concat(lines, '\n')
end

---@param mode string
---@return string
function WikiCopyPaste._getOpponent(mode)
	if mode == Opponent.solo then
		return '{{SoloOpponent||flag=|team=|score=}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent||score=}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

return WikiCopyPaste
