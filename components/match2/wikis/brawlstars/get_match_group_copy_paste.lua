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

local _CONVERT_PICK_BAN_ENTRY = {
	none = {},
	pick = {'pick'},
	ban = {'ban'},
	player = {'player'},
	['pick + ban'] = {'pick', 'ban'},
	['pick + player'] = {'player', 'pick'},
	['ban + player'] = {'player', 'ban'},
	all = {'player', 'pick', 'ban'},
}
local _PARAM_TO_SHORT = {
	pick = 'c',
	ban = 'b',
	player = 'p',
}
local _LIMIT_OF_PARAM = {
	pick = 3,
	ban = 2,
	player = 3,
}

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

	lines = wikiCopyPaste._getMaps(lines, bestof, args, index, opponents)

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
function wikiCopyPaste._getMaps(lines, bestof, args, index, numberOfOpponents)
	if bestof > 0 then
		local map = '{{Map'
			.. '\n' .. indent .. indent .. '|map=|maptype='
			.. '\n' .. indent .. indent .. '|score1=|score2='

		for _, item in ipairs(_CONVERT_PICK_BAN_ENTRY[args.pickBan or ''] or {}) do
			map = map .. wikiCopyPaste._pickBanParams(item, numberOfOpponents)
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

function wikiCopyPaste._pickBanParams(key, numberOfOpponents)
	local shortKey = _PARAM_TO_SHORT[key]
	local limit = _LIMIT_OF_PARAM[key]
	local display = ''

	for opponentIndex = 1, numberOfOpponents do
		display = display .. '\n' .. indent .. indent
		for keyIndex = 1, limit do
			display = display .. '|t' .. opponentIndex .. shortKey .. keyIndex .. '='
		end
	end

	return display
end

return wikiCopyPaste
