---
-- @Liquipedia
-- wiki=rainbowsix
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
	[4] = 'pick,ban,pick,ban',
	[5] = 'pick,ban,pick,decider',
	[6] = 'pick,pick,pick,ban',
	[7] = 'pick,pick,pick,decider',
	[8] = 'pick,pick,pick,pick,ban',
	[9] = 'pick,pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = args.score == 'true'
	local mapDetails = args.detailedMap == 'true'
	local mapDetailsOT = args.detailedMapOT == 'true'
	local mapVeto = args.mapVeto == 'true'
	local streams = args.streams == 'true'
	local out = '{{Match' .. '\n\t|date=|finished='

	if streams then
		out = out .. '\n\t|twitch=|youtube=|vod='
	end

	for i = 1, opponents do
		out = out .. '\n\t|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, showScore)
	end

	if mapVeto and VETOES[bestof] then
		out = out .. '\n\t|mapveto={{MapVeto'
		out = out .. '\n\t\t|firstpick='
		out = out .. '\n\t\t|types=' .. VETOES[bestof]
		out = out .. '\n\t\t|t1map1=|t2map1='
		out = out .. '\n\t\t|t1map2=|t2map2='
		out = out .. '\n\t\t|t1map3=|t2map3='
		out = out .. '\n\t\t|decider='
		out = out .. '\n\t}}'
	end
	for i = 1, bestof do
		out = out .. '\n\t|map' .. i .. '={{Map|map='
		if not mapDetails then
			out = out .. '|score1=|score2='
		end
		out = out .. '|finished='
		if mapDetails then
			out = out .. '\n\t\t|t1ban1=|t1ban2='
			out = out .. '\n\t\t|t2ban1=|t2ban2='
			out = out .. '\n\t\t|t1firstside='
			if mapDetailsOT then
				out = out .. '|t1firstsideot='
			end
			out = out .. '\n\t\t|t1atk=|t1def='
			if mapDetailsOT then
				out = out .. '|t1otatk=|t1otdef='
			end
			out = out .. '\n\t\t|t2atk=|t2def='
			if mapDetailsOT then
				out = out .. '|t2otatk=|t2otdef='
			end
			out = out .. '\n\t'
		end
		out = out .. '}}'
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
