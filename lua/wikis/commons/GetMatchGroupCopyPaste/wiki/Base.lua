---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
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
	duo = Opponent.duo,
	trio = Opponent.trio,
	quad = Opponent.quad,
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

	return table.concat(Array.extend({},
		'{{Match',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return '\n' .. INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		'\n' .. INDENT .. '|finished=\n' .. INDENT .. '|date=\n' .. INDENT .. '}}'
	))
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
	elseif Opponent.typeIsParty(mode) then
		local partySize = Opponent.partySize(mode)
		--can not be nil due to the check typeIsParty check
		---@cast partySize -nil

		local parts = {'{{' .. mw.getContentLanguage():ucfirst(mode) .. 'Opponent'}
		Array.forEach(Array.range(1, partySize), function(playerIndex)
			local prefix = '|p' .. playerIndex
			Array.appendWith(parts,
				prefix .. '=',
				prefix .. 'flag='
			)
		end)
		return table.concat(Array.append(parts, score .. '}}'))
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

---subfunction used to generate the code for the Opponent template in Ffa matches, depending on the type of opponent
---@param mode string
---@param mapCount integer
---@return string
function WikiCopyPaste.getFfaOpponent(mode, mapCount)
	local mapScores = table.concat(Array.map(Array.range(1, mapCount), function(idx)
		return '|m' .. idx .. '={{MS||}}'
	end))

	if mode == Opponent.solo then
		return '{{SoloOpponent||flag=' .. mapScores .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|' .. mapScores .. '}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

---function that sets the text that starts the invoke of the MatchGroup Modules,
---contains mandatory stuff like bracketid, templateid and MatchGroup type (matchlist or bracket)
---@param template string?
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
---@param template string?
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
