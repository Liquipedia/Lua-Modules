---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local wikiCopyPaste = Table.copy(Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base', {requireDevIfEnabled = true}))

local GSL_STYLE_WITH_EXTRA_MATCH_INDICATOR = 'gf'
local GSL_WINNERS = 'winners'
local GSL_LOSERS = 'losers'

--returns the Code for a Match, depending on the input
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local streams = Logic.readBool(args.streams)
	local showScore = Logic.readBool(args.score)
	local mapDetails = Logic.readBool(args.detailedMap)
	local mapDetailsOT = Logic.readBool(args.detailedMapOT)
	local hltv = Logic.readBool(args.hltv)
	local mapStats = args.mapStats and wikiCopyPaste._ipairsSet(mw.text.split(args.mapStats, ', ')) or {}
	local matchMatchpages = args.matchMatchpages and
								wikiCopyPaste._ipairsSet(mw.text.split(args.matchMatchpages, ', ')) or {}
	local out = '{{Match'

	if hltv then
		table.insert(mapStats, 'Stats')
		table.insert(matchMatchpages, 1, 'HLTV')
	end

	out = out .. '\n\t'
	for i = 1, opponents do
		out = out .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode, showScore)
	end

	out = out .. '\n\t|date=|finished='

	if streams then
		table.insert(mapStats, 'vod')
		out = out .. '\n\t|twitch=|youtube=|vod='
	end

	if #matchMatchpages > 0 then
		out = out .. '\n\t'
		for _, matchpage in ipairs(matchMatchpages) do
			out = out .. '|' .. matchpage:lower() .. '='
		end
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
		end
		out = out .. '}}'
	end

	return out .. '\n}}'
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

function wikiCopyPaste._ipairsSet(tbl)
	local valuesSet = {}
	local array = {}

	for _, value in ipairs(tbl) do
		if not valuesSet[value] then
			table.insert(array, value)
			valuesSet[value] = true
		end
	end

	return array
end

function wikiCopyPaste.getStart(template, id, modus, args)
	args.namedMatchParams = false
	local out = '{{' .. (
		(modus == 'bracket' and
			('Bracket|Bracket/' .. template)
		) or (modus == 'singlematch' and 'SingleMatch')
		or 'Matchlist') ..
		'|id=' .. id

	local gslStyle = args.gsl
	if modus == 'matchlist' and gslStyle then
		args.customHeader = false
		if String.startsWith(gslStyle:lower(), GSL_STYLE_WITH_EXTRA_MATCH_INDICATOR) then
			args.matches = 6
			if String.endsWith(gslStyle:lower(), GSL_WINNERS) then
				out = out .. '|gsl=' .. 'winnersfirst'
			elseif String.endsWith(gslStyle:lower(), GSL_LOSERS) then
				out = out .. '|gsl=' .. 'losersfirst'
			end
			out = out .. '\n|M6header=Grand Final'
		else
			args.matches = 5
			out = out .. '|gsl=' .. gslStyle
		end
	end

	return out, args
end

return wikiCopyPaste
