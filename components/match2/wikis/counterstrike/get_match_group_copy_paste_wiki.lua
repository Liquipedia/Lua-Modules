---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')
local Set = require('Module:Set')

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))


--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local streams = args.streams == 'true'
	local showScore = args.score == 'true'
	local mapDetails = args.detailedMap == 'true'
	local mapDetailsOT = args.detailedMapOT == 'true'
	local hltv = args.hltv == 'true'
	local mapStats = args.mapStats and Set(mw.text.split(args.mapStats, ', ')):toArray() or {}
	local matchMatchpages = args.matchMatchpages and Set(mw.text.split(args.matchMatchpages, ', ')):toArray() or {}
	local out = '{{Match' .. '\n\t|date=|finished='

	if hltv then
		table.insert( mapStats, 1, 'Stats' )
		table.insert( matchMatchpages, 1, 'HLTV' )
	end

	if streams then
		table.insert( mapStats, 1, 'vod' )
		out = out .. '\n\t|twitch=|youtube=|vod='
	end

	for i = 1, opponents do
		out = out .. '\n\t|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, showScore)
	end

	for i = 1, bestof do
		out = out .. '\n\t|map' .. i .. '={{Map|map='
		if not mapDetails then
			out = out .. '|score1=|score2='
		end
		out = out .. '|finished='
		if mapDetails then
			out = out .. '\n\t\t|t1firstside=|t1t=|t1ct=|t2t=|t2ct='
			if mapDetailsOT then
				out = out .. '\n\t\t|o1t1firstside=|o1t1t=|o1t1ct=|o1t2t=|o1t2ct='
			end
		end
		if #mapStats > 0 then
			out = out .. '\n\t\t'
			for _, stat in ipairs(mapStats) do
				out = out .. '|' .. stat:lower() .. '='
			end
			out = out .. '\n\t'
		end
		out = out .. '}}'
	end

	if #matchMatchpages > 0 then
		for _, matchpage in ipairs(matchMatchpages) do
			out = out .. '\n\t|' .. matchpage:lower() .. '='
		end
	end

	return out .. '\n\t}}'
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function wikiCopyPaste._getOpponent(mode, showScore)
	local score = showScore and '|score=' or ''

	if mode == 'solo' then
		return '{{PlayerOpponent||flag=|team=' .. score .. '}}'
	elseif mode == 'team' then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == 'literal' then
		return '{{LiteralOpponent|}}'
	end
end

return wikiCopyPaste