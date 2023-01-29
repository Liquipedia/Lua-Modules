---
-- @Liquipedia
-- wiki=valorant
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

local VETOES = {
	[0] = '',
	[1] = 'ban,ban,ban,decider',
	[2] = 'ban,ban,pick,ban',
	[3] = 'ban,pick,ban,decider',
	[4] = 'ban,pick,pick,ban',
	[5] = 'ban,pick,pick,decider',
	[6] = 'pick,pick,pick,ban',
	[7] = 'pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '  '
	local showScore = args.score == 'true'
	local mapDetails = args.detailedMap == 'true'
	local mapDetailsOT = args.detailedMapOT == 'true'
	local mapVeto = args.mapVeto == 'true'
	local streams = args.streams == 'true'
	local lines = {}
	table.insert(lines, '{{Match')
	table.insert(lines, indent .. '|date=|finished=')

	if streams then
		table.insert(lines, indent .. '|twitch=|youtube=|vod=')
	end

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, showScore))
	end

	if mapVeto and VETOES[bestof] then
		table.insert(lines, indent .. '|mapveto={{MapVeto')
		table.insert(lines, indent .. indent .. '|firstpick=')
		table.insert(lines, indent .. indent .. '|types=' .. VETOES[bestof])
		table.insert(lines, indent .. indent .. '|t1map1=|t2map1=')
		table.insert(lines, indent .. indent .. '|t1map2=|t2map2=')
		table.insert(lines, indent .. indent .. '|t1map3=|t2map3=')
		table.insert(lines, indent .. indent .. '|decider=')
		table.insert(lines, indent .. '}}')
	end
	for i = 1, bestof do
		table.insert(lines, indent .. '|map' .. i .. '={{Map|map=')
		if not mapDetails then
			lines[#lines] = lines[#lines] .. '|score1=|score2='
		end
		lines[#lines] = lines[#lines] .. '|finished='
		if mapDetails then
			table.insert(lines, indent .. indent .. '|t1firstside=')
			table.insert(lines, indent .. indent .. '|t1atk=|t1def=')
			if mapDetailsOT then
				lines[#lines] = lines[#lines] .. '|t1otatk=|t1otdef='
			end
			table.insert(lines, indent .. indent .. '|t2atk=|t2def=')
			if mapDetailsOT then
				lines[#lines] = lines[#lines] .. '|t2otatk=|t2otdef='
			end
			table.insert(lines, indent)
		end
		lines[#lines] = lines[#lines] .. '}}'
	end
	table.insert(lines,'}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, showScore)
	local score = showScore and '|score=' or ''

	if mode == 'team' then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == 'literal' then
		return '{{LiteralOpponent|}}'
	end
end

return wikiCopyPaste
