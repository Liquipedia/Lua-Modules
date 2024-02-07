---
-- @Liquipedia
-- wiki=commons
-- page=Module:GetMatchGroupCopyPaste/wiki/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

---Base-WikiSpecific Code for MatchList and Bracket Code Generators
---@class Match2CopyPasteBase:Match2CopyPaste
local WikiCopyPaste = Class.new()

local INDENT = '    '

--allowed opponent types on the wiki
local MODES = {
	['solo'] = 'solo',
	['team'] = 'team',
	['literal'] = 'literal',
}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = 'team'

---returns the cleaned opponent type
---@param mode string?
---@return string
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

---subfunction used to generate the code for the Map template
---sets up as many maps as specified via the bestoff param
---@param bestof integer
---@return unknown
function WikiCopyPaste._getMaps(bestof)
	local map = '{{Map|map=}}'
	local lines = Array.map(Array.range(1, bestof), function(mapIndex)
		return INDENT .. '|map' .. mapIndex .. '=' .. map
	end)

	return '\n' .. table.concat(lines, '\n')
end

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string?
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local out = tostring(mw.message.new('BracketConfigMatchTemplate'))
	local opponent = WikiCopyPaste._getOpponent(WikiCopyPaste.getMode(mode))

	if out == '⧼BracketConfigMatchTemplate⧽' then
		local lines = {'{{Match\n' .. INDENT}
		Array.extendWith(lines,
			Array.map(Array.range(1, opponents), function(opponentIndex)
				return '\n' .. INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
			end),
			'\n' .. INDENT .. '|finished=\n' .. INDENT .. '|tournament=\n' .. INDENT .. '}}'
		)
		return table.concat(lines)
	end

	out = out:gsub('<nowiki>', ''):gsub('</nowiki>', '')
	Array.forEach(Array.range(1, opponents), function(opponentIndex)
		local opponentKey = '|opponent' .. opponentIndex .. '='
		out = out:gsub(opponentKey, opponentKey .. opponent)
	end)

	out = out
		:gsub('|map1=.*\n' , '<<maps>>')
		:gsub('|map%d+=.*\n' , '')
		:gsub('<<maps>>' , WikiCopyPaste._getMaps(bestof))

	return out
end

---subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@return string
function WikiCopyPaste._getOpponent(mode)
	if mode == 'solo' then
		return '{{SoloOpponent||flag=|team=|score=}}'
	elseif mode == 'team' then
		return '{{TeamOpponent||score=}}'
	elseif mode == 'literal' then
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
	local out = tostring(mw.message.new('BracketConfigBracketTemplate'))
	local matchGroupTypeCopyPaste = WikiCopyPaste.getMatchGroupTypeCopyPaste(modus, template)

	if out == '⧼BracketConfigBracketTemplate⧽' then
		out = '{{' .. matchGroupTypeCopyPaste .. '|id=' .. id

		return out, args
	end

	out = out
		:gsub('<nowiki>', '')
		:gsub('</nowiki>', '')
		:gsub('<<matches>>.*', '')
		:gsub('<<bracketid>>', id)
		:gsub('^{{#invoke:[mM]atchGroup|[bB]racket', 'Bracket')
		:gsub('[Bb]racket|<<templatename>>', matchGroupTypeCopyPaste)

	return out, args
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
