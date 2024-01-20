---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

]]--

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

--allowed opponent types on the wiki
local MODES = {
	['solo'] = '1v1',
	['1v1'] = '1v1',
	['2v2'] = '2v2',
	['team'] = 'team',
	['literal'] = 'literal',
}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = '1v1'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '    '

	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local score = args.score == 'true' and '|score=' or nil
	local bans = Logic.readBool(args.bans)

	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|youtube='} or {}
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score))
	end
	if bans then
		table.insert(lines, indent .. '|t1bans={{Cards|}}|t2bans={{Cards|}}')
	end

	if bestof ~= 0 then
		if mode == '2v2' then
			for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map|winner=',
				indent .. indent .. '<!-- Card picks -->',
				indent .. indent .. '|t1p1c={{Cards| | | | | | | | }}',
				indent .. indent .. '|t1p2c={{Cards| | | | | | | | }}',
				indent .. indent .. '|t2p1c={{Cards| | | | | | | | }}',
				indent .. indent .. '|t2p2c={{Cards| | | | | | | | }}'
			)
			Array.appendWith(lines,
				indent .. '}}'
			)
		end
		elseif mode == 'team' then
			for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map|winner=|subgroup=',
				indent .. indent .. '<!-- Players -->',
				indent .. indent .. '|t1p1=',
				indent .. indent .. '|t2p1='
			)
			Array.appendWith(lines,
				indent .. '}}'
			)
		end
		else
			for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map|winner=',
				indent .. indent .. '<!-- Card picks -->',
				indent .. indent .. '|t1p1c={{Cards| | | | | | | | }}',
				indent .. indent .. '|t2p1c={{Cards| | | | | | | | }}'
			)
			Array.appendWith(lines,
				indent .. '}}'
			)
		end
	end
end
	
	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == '1v1' then
		out = '{{SoloOpponent||flag=' .. (score or '') .. '}}'
	elseif mode == '2v2' then
		out = '{{2v2Opponent|p1=|p1flag=|p2=|p2flag=' .. (score or '') .. '}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent|' .. (score or '') .. '}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

return wikiCopyPaste
