---
-- @Liquipedia
-- wiki=leagueoflegends
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
	local indent = '  '

	if bestof == 0 and args.score ~= 'false' then
		args.score = 'true'
	end
	local displayScore = args.score == 'true'
	local bans = args.bans == 'true'

	local lines = Array.extend(
		'{{Match2', -- Template:Match is used by match1 for now. Using Template:Match2 until it has been worked away.
		args.needsWinner == 'true' and indent .. '|winner=' or nil
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, displayScore))
	end

	if args.hasDate == 'true' then
		Array.appendWith(lines,
			indent .. '|date=',
			indent .. '|finished=',
			indent .. '|twitch=|youtube=',
			indent .. '|reddit=|gol='
		)
	end

	for i = 1, bestof do
		Array.appendWith(lines, indent .. '|vodgame'.. i ..'=')
	end

	for i = 1, bestof do
		Array.appendWith(lines,
			indent .. '|map' .. i .. '={{Map',
			indent .. indent .. '|team1side=',
			indent .. indent .. '|t1c1=|t1c2=|t1c3=|t1c4=|t1c5='
		)

		if bans then
			Array.appendWith(lines,
				indent .. indent .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5='
			)
		end

		Array.appendWith(lines,
			indent .. indent .. '|team2side=',
			indent .. indent .. '|t2c1=|t2c2=|t2c3=|t2c4=|t2c5='
		)

		if bans then
			Array.appendWith(lines,
				indent .. indent .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5='
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
