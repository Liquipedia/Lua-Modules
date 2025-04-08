---
-- @Liquipedia
-- wiki=heroes
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
	local veto = args.veto == 'true'
	local vetoBanRounds = tonumber(args.vetoBanRounds) or 0

	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|twitch=', indent .. '|caster1=', indent .. '|caster2=', indent .. '|comment='} or {}
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score))
	end

	if veto and bestof > 0 then
		local preFilledVetoTypes = string.rep('ban,', vetoBanRounds)
			.. string.rep('pick,', bestof - 1) .. 'pick'

		Array.appendWith(lines,
			indent .. '|mapveto={{MapVeto',
			indent .. indent .. '|format=By turns',
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
				indent .. '|map' .. i .. '={{Map|map=',
				indent .. indent .. '|team1side=blue |team2side=red |winner=',
				indent .. indent .. '|vod= |length=',
				indent .. indent .. '<!-- Hero picks -->',
				indent .. indent .. '|t1h1= |t1h2= |t1h3= |t1h4= |t1h5=',
				indent .. indent .. '|t2h1= |t2h2= |t2h3= |t2h4= |t2h5='
			)
			if bans then
				Array.appendWith(lines,
					indent .. indent .. '<!-- Hero bans -->',
					indent .. indent .. '|t1b1=|t1b2=|t1b3=',
					indent .. indent .. '|t2b1=|t2b2=|t2b3='
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
