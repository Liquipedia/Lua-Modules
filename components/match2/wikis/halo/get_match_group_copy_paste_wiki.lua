---
-- @Liquipedia
-- wiki=halo
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

]]--

local wikiCopyPaste = require('Module:GetMatchGroupCopyPaste/wiki/Base')

--allowed opponent types on the wiki (archon and 2v2 both are of type
--"duo", but they need different code, hence them both being available here)
local MODES = {
	['solo'] = 'solo',
	['team'] = 'team',
	}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = 'team'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local score = args.score == 'true' and '|score=' or ''
	local hasDate = args.hasDate == 'true' and '\n\t|date=\n\t|twitch=' or ''
	local needsWinner = args.needsWinner == 'true' and '\n\t|winner=' or ''
	local out = '{{Match' .. (index == 1 and ('|bestof=' .. (bestof ~= 0 and bestof or '')) or '') ..
		needsWinner .. hasDate

	for i = 1, opponents do
		out = out .. '\n\t|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score)
	end

	if bestof ~= 0 then
		for i = 1, bestof do
			out = out .. '\n\t|map' .. i .. '={{Map|map=|winner='
				.. '\n\t\t|score1=|score2='
				.. '\n\t\t|winner=\n\t}}'
		end
	end

	return out .. '\n}}'
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == 'solo' then
		out = '{{SoloOpponent||flag=' .. score .. '}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent|' .. score .. '}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

return wikiCopyPaste
