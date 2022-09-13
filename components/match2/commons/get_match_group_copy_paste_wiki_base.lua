---
-- @Liquipedia
-- wiki=commons
-- page=Module:GetMatchGroupCopyPaste/wiki/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

Base-WikiSpecific Code for MatchList and Bracket Code Generators

adjust this to fit the needs of your wiki^^

]]--

local wikiCopyPaste = {}

--allowed opponent types on the wiki
local MODES = {
	['solo'] = 'solo',
	['team'] = 'team',
	['literal'] = 'literal',
}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = 'team'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
function wikiCopyPaste._getMaps(bestof)
	local map = '{{Map|map=}}'
	local out = ''
	for i = 1, bestof do
		out = out .. '\n	|map' .. i .. '=' .. map
	end

	return out
end

--returns the Code for a Match, depending on the input
--for more customization please change stuff here^^
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local out = tostring(mw.message.new('BracketConfigMatchTemplate'))
	if out == '⧼BracketConfigMatchTemplate⧽' then
		out = '{{Match\n    '
		for i = 1, opponents do
			out = out .. '\n    |opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode)
		end
		out = out .. '\n    |finished=\n    |tournament=\n    }}'
	else
		out = string.gsub(out, '<nowiki>', '')
		out = string.gsub(out, '</nowiki>', '')
		for i = 1, opponents do
			out = string.gsub(out, '|opponent' .. i .. '=' , '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode))
		end

		out = string.gsub(out, '|map1=.*\n' , '<<maps>>')
		out = string.gsub(out, '|map%d+=.*\n' , '')
		out = string.gsub(out, '<<maps>>' , wikiCopyPaste._getMaps(bestof))
	end

	return out
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode)
	local out

	if mode == 'solo' then
		out = '{{SoloOpponent||flag=|team=|score=}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent||score=}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

--function that sets the text that starts the invoke of the MatchGroup Moduiles,
--contains madatory stuff like bracketid, templateid and MatchGroup type (matchlist or bracket)
--on sc2 also used to link to the documentation pages about the new bracket/match system
function wikiCopyPaste.getStart(template, id, modus, args)
	local out = tostring(mw.message.new('BracketConfigBracketTemplate'))
	if out == '⧼BracketConfigBracketTemplate⧽' then
		out = '{{' .. (
			(modus == 'bracket' and
				('Bracket|Bracket/' .. template)
			) or (modus == 'singlematch' and 'SingleMatch')
			or 'Matchlist') ..
			'|id=' .. id
	else
		out = string.gsub(out, '<nowiki>', '')
		out = string.gsub(out, '</nowiki>', '')
		out = string.gsub(out, '<<matches>>.*', '')
		out = string.gsub(out, '<<bracketid>>', id)
		out = string.gsub(out, '^{{#invoke:[mM]atchGroup|[bB]racket', 'Bracket')
		out = string.gsub(out, '[Bb]racket|<<templatename>>',
			(
				modus == 'bracket' and ('Bracket|Bracket/' .. template)
				or modus == 'singlematch' and 'SingleMatch'
				or 'Matchlist'
			)
		)
	end

	return out, args
end

return wikiCopyPaste
