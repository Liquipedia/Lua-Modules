---
-- @Liquipedia
-- wiki=dota2
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

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = ''

	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local displayScore = args.score == 'true'
	local bans = args.bans == 'true'

	local lines = Array.extend(
		'{{Match2', -- Template:Match is used by match1 for now. Using Template:Match2 until it has been worked away.
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and indent .. '|winner=' or nil
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, displayScore))
	end

	if args.hasDate == 'true' then
		Array.appendWith(lines,
			indent .. '|date=',
			indent .. '|finished=',
			indent .. '|twitch='
		)
	end

	for i = 1, bestof do
		Array.appendWith(lines, indent .. '|vodgame'.. i ..'=')
	end

	for i = 1, bestof do
		Array.appendWith(lines, indent .. '|matchid'.. i ..'=')
	end

	for i = 1, bestof do
		Array.appendWith(lines,
			indent .. '|map' .. i .. '={{Map',
			indent .. indent .. '|team1side=',
			indent .. indent .. '|t1h1=|t1h2=|t1h3=|t1h4=|t1h5='
		)

		if bans then
			Array.appendWith(lines,
				indent .. indent .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=|t1b6=|t1b7='
			)
		end

		Array.appendWith(lines,
			indent .. indent .. '|team2side=',
			indent .. indent .. '|t2h1=|t2h2=|t2h3=|t2h4=|t2h5='
		)

		if bans then
			Array.appendWith(lines,
				indent .. indent .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5=|t2b6=|t2b7='
			)
		end

		Array.appendWith(lines,
			indent .. indent .. '|length=|winner=',
			indent .. '}}'
		)
	end

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, displayScore)
	local scoreText = displayScore and '|score=' or ''

	if mode == 'solo' then
		return '{{SoloOpponent||flag=' .. scoreText .. '}}'
	elseif mode == 'team' then
		return '{{TeamOpponent|' .. scoreText .. '}}'
	elseif mode == 'literal' then
		return '{{Literal|}}'
	end
end

return wikiCopyPaste
