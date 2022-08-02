---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')
local Logic = require('Module:Logic')
local Set = require('Module:Set')
local Opponent = require('Module:Opponent')

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))


--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local streams = Logic.readBool(args.streams)
	local showScore = Logic.readBool(args.score)
	local mapDetails = Logic.readBool(args.detailedMap)
	local mapDetailsOT = Logic.readBool(args.detailedMapOT)
	local hltv = Logic.readBool(args.hltv)
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

	if mode == Opponent.solo then
		return '{{PlayerOpponent||flag=|team=' .. score .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == Opponent.literal then
		return '{{LiteralOpponent|}}'
	end
end

return wikiCopyPaste