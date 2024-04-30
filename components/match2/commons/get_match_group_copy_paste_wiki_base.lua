---
-- @Liquipedia
-- wiki=commons
-- page=Module:GetMatchGroupCopyPaste/wiki/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---Base-WikiSpecific Code for MatchList and Bracket Code Generators
---@class Match2CopyPasteBase
local WikiCopyPaste = Class.new()

local INDENT = '    '
WikiCopyPaste.Indent = INDENT

--allowed opponent types on the wiki
local MODES = {
	solo = Opponent.solo,
	team = Opponent.team,
	literal = Opponent.literal,
}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = Opponent.team

---returns the cleaned opponent type
---@param mode string?
---@return string
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

---subfunction used to generate the code for the Map template
---sets up as many maps as specified via the bestoff param
---@param bestof integer
---@return string
function WikiCopyPaste._getMaps(bestof)
	local map = '{{Map|map=}}'
	local lines = Array.map(Array.range(1, bestof), function(mapIndex)
		return INDENT .. '|map' .. mapIndex .. '=' .. map
	end)

	return '\n' .. table.concat(lines, '\n')
end

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)

	local lines = {'{{Match\n' .. INDENT}
	Array.extendWith(lines,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return '\n' .. INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		'\n' .. INDENT .. '|finished=\n' .. INDENT .. '|date=\n' .. INDENT .. '}}'
	)
	return table.concat(lines)
end

---subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@param showScore boolean?
---@return string
function WikiCopyPaste.getOpponent(mode, showScore)
	local score = showScore and '|score=' or ''
	if mode == Opponent.solo then
		return '{{SoloOpponent||flag=' .. score .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

---function that sets the text that starts the invoke of the MatchGroup Moduiles,
---contains madatory stuff like bracketid, templateid and MatchGroup type (matchlist or bracket)
---@param template string
---@param id string
---@param modus string
---@param args table
---@return string
---@return table
function WikiCopyPaste.getStart(template, id, modus, args)
	local matchGroupTypeCopyPaste = WikiCopyPaste.getMatchGroupTypeCopyPaste(modus, template)

	return '{{' .. matchGroupTypeCopyPaste .. '|id=' .. id, args
end

---@param modus string
---@param template string
---@return string
function WikiCopyPaste.getMatchGroupTypeCopyPaste(modus, template)
	if modus == 'bracket' then
		return 'Bracket|Bracket/' .. template
	elseif modus == 'singlematch' then
		return 'SingleMatch'
	end

	return 'Matchlist'
end

return WikiCopyPaste
