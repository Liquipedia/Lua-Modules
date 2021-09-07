---
-- @Liquipedia
-- wiki=runeterra
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

atm this only supports 1v1 matches

]]--

local wikiCopyPaste = {}

--allowed opponent types on the wiki (add more here once they are supported)
local MODES = {
	['1v1'] = '1v1',
	}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = '1v1'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local needsWinner = (args.needsWinner == 'true' or bestof > 0) and '\n    |winner=' or ''
	local out = '{{Match' .. (index == 1 and ('|bestof=' .. (bestof ~= 0 and bestof or '')) or '') ..
		needsWinner .. '\n    |date=\n    |twitch='

	for i = 1, opponents do
		out = out .. '\n    |opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode)
	end

	if bestof ~= 0 then
		if mode == '1v1' then
			for i = 1, bestof do
				out = out .. '\n    |game' .. i .. '={{Game|deck1=|deck2=|score1=|score2=|winner=}}'
			end
		else
			error('Opponent type "' .. mode .. '" is not yet supported')
		end
	end

	return out .. '\n    }}'
end

--subfunction used to generate the code for the Opponent template,
--depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == '1v1' then
		out = '{{SoloOpponent||displayname=|flag=|score=}}'
	else
		error('Opponent type "' .. mode .. '" is not yet supported')
	end

	return out
end

return wikiCopyPaste
