---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')
local Array = require('Module:Array')
local String = require('Module:StringUtils')

--[[

WikiSpecific Code for MatchList, Bracket and SingleMatch Code Generators

]]--

local indent = '    '

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend(
		'{{Match',
		index == 1 and (indent .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.hasDate == 'true' and {indent .. '|date=', indent .. '|twitch='} or {}
	)

	local score = args.score == 'true' and '|score=' or nil
	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, score or ''))
	end

	lines = wikiCopyPaste._getMaps(lines, bestof, args, index)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, score)
	local out

	if mode == 'solo' then
		out = '{{SoloOpponent||flag=|team=' .. score .. '}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent|' .. score .. '}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
function wikiCopyPaste._getMaps(lines, bestof, args, index)
	if bestof > 0 then
		local map = '{{Map'
			.. '\n' .. indent .. indent .. '|map=|maptype='
			.. '\n' .. indent .. indent .. '|score1=|score2='

		if args.pickBan == 'both' or args.pickBan == 'pick' then
			map = map .. '\n' .. indent .. indent .. '|t1p1=|t1p2=|t1p3='
				.. '\n' .. indent .. indent .. '|t2p1=|t2p2=|t2p3='
		end

		if args.pickBan == 'both' or args.pickBan == 'ban' then
			map = map .. '\n' .. indent .. indent .. '|t1b1=|t1b2=|t1b3='
				.. '\n' .. indent .. indent .. '|t2b1=|t2b2=|t2b3='
		end

		--first map has additional mapBestof if it is the first match
		local mapBestof = ''
		if index == 1 and String.isNotEmpty(args.mapBestof) then
			mapBestof = '\n' .. indent .. indent .. '|bestof=' .. args.mapBestof
		end
		table.insert(lines, indent .. '|map1=' .. map .. mapBestof .. '\n' .. indent .. '}}')

		--other maps do not have mapBestof
		map = map .. '\n' .. indent .. '}}'
		if bestof > 1 then
			for i = 1, bestof do
				table.insert(lines, indent .. '|map' .. i .. '=' .. map)
			end
		end
	end

	return lines
end

return wikiCopyPaste
