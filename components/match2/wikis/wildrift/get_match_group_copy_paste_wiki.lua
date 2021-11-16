---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Table = require('Module:Table')

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

]]--

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

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

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '    '

	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local score = args.score == 'true' and '|score=' or nil
	local bans = args.bans == 'true'
	local kda = args.kda == 'true'

	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|twitch='} or {}
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score))
	end

	if bestof ~= 0 then
		for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map',
				indent .. indent .. '|team1side=|team2side=|length=|winner=',
				indent .. indent .. '<!-- Champion/Hero picks -->',
				indent .. indent .. '|t1c1=|t1c2=|t1c3=|t1c4=|t1c5=',
				indent .. indent .. '|t2c1=|t2c2=|t2c3=|t2c4=|t2c5='
			)
			if bans then
				Array.appendWith(lines,
					indent .. indent .. '<!-- Champion/Hero bans -->',
					indent .. indent .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=',
					indent .. indent .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5='
				)
			end
			if kda then
				Array.appendWith(lines,
					indent .. indent .. '<!-- KDA -->',
					indent .. indent .. '|t1kda1=|t1kda2=|t1kda3=|t1kda4=|t1kda5=',
					indent .. indent .. '|t2kda1=|t2kda2=|t2kda3=|t2kda4=|t2kda5='
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
function wikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == 'solo' then
		out = '{{SoloOpponent||flag=' .. (score or '') .. '}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent|' .. (score or '') .. '}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

return wikiCopyPaste
