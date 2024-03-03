---
-- @Liquipedia
-- wiki=worldoftanks
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
	local veto = args.veto == 'true'
	local vetoBanRounds = tonumber(args.vetoBanRounds) or 0
	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|youtube=|twitch='} or {}
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score))
	end

	if veto and bestof > 0 then
		local preFilledVetoTypes = string.rep('ban,', vetoBanRounds)
			.. string.rep('pick,', bestof - 1) .. 'pick'
		
		Array.appendWith(lines,
			indent .. '|mapveto={{MapVeto',
			indent .. indent .. '|firstpick=',
			indent .. indent .. '|types=' .. preFilledVetoTypes
		)

		for roundIndex = 1, (vetoBanRounds + bestof) do
			Array.appendWith(lines, indent .. indent .. '|t1map' .. roundIndex .. '=|t2map' .. roundIndex .. '=')
		end

		Array.appendWith(lines, indent .. '}}')
	end

	if bestof ~= 0 then
		for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i .. '={{Map|map=|score1=|score2=|winner=}}'
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
