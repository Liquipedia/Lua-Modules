---
-- @Liquipedia
-- wiki=smite
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Table = require('Module:Table')
local Opponent = require('Module:Opponent')

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

]]--

local WikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

--allowed opponent types on the wiki
local MODES = {
	solo = 'solo',
	team = 'team',
	literal = 'literal',
}

--default opponent type (used if the entered mode is not found in the above table)
local DEFAULT_MODE = 'team'

--returns the cleaned opponent type
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DEFAULT_MODE
end

--returns the Code for a Match, depending on the input
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '    '

	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local score = args.score == 'true' and '|score=' or nil
	local bans = args.bans == 'true'

	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|youtube='} or {}
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode, score))
	end

	if bestof ~= 0 then
		for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map',
				indent .. indent .. '|team1side=|team2side=|length=|winner=',
				indent .. indent .. '|caster1=|caster2=|mvp=',
				indent .. indent .. '<!-- Gods picks -->',
				indent .. indent .. '|t1g1=|t1g2=|t1g3=|t1g4=|t1g5=',
				indent .. indent .. '|t2g1=|t2g2=|t2g3=|t2g4=|t2g5='
			)
			if bans then
				Array.appendWith(lines,
					indent .. indent .. '<!-- Gods bans -->',
					indent .. indent .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=',
					indent .. indent .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5='
				)
			end
			Array.appendWith(lines,
				indent .. '}}'
			)
		end
	end

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function WikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == Opponent.solo then
		out = '{{SoloOpponent||flag=' .. (score or '') .. '}}'
	elseif mode == Opponent.team then
		out = '{{TeamOpponent|' .. (score or '') .. '}}'
	elseif mode == Opponent.literal then
		out = '{{Literal|}}'
	end

	return out
end

return WikiCopyPaste
