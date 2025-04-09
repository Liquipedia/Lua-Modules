---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

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
	ban = 1,
	player = 3,
}

---@class OmegastrikersMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

--returns the Code for a Match, depending on the input
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.hasDate == 'true' and {INDENT .. '|date=', INDENT .. '|twitch='} or {}
	)

	local score = args.score == 'true' and '|score=' or nil
	for i = 1, opponents do
		table.insert(lines, INDENT .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode, score or ''))
	end

	lines = WikiCopyPaste._getMaps(lines, bestof, args, index, opponents)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function WikiCopyPaste._getOpponent(mode, score)
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
function WikiCopyPaste._getMaps(lines, bestof, args, matchIndex, numberOfOpponents)
	if bestof > 0 then
		local map = '{{Map'
			.. '\n' .. INDENT .. INDENT .. '|map='
			.. '\n' .. INDENT .. INDENT .. '|score1=|score2='

		for _, item in ipairs(_CONVERT_PICK_BAN_ENTRY[args.pickBan or ''] or {}) do
			map = map .. WikiCopyPaste._pickBanParams(item, numberOfOpponents)
		end

		for mapIndex = 1, bestof do
			local currentMap = INDENT .. '|map' .. mapIndex .. '=' .. map
			--first map has additional mapBestof if it is the first match
			if matchIndex == 1 and mapIndex == 1 and String.isNotEmpty(args.mapBestof) then
				currentMap = currentMap .. '\n' .. INDENT .. INDENT .. '|bestof=' .. args.mapBestof
			end
			currentMap = currentMap .. '\n' .. INDENT .. '}}'
			table.insert(lines, currentMap)
		end
	end

	return lines
end

function WikiCopyPaste._pickBanParams(key, numberOfOpponents)
	local shortKey = _PARAM_TO_SHORT[key]
	local limit = _LIMIT_OF_PARAM[key]
	local display = ''

	for opponentIndex = 1, numberOfOpponents do
		display = display .. '\n' .. INDENT .. INDENT
		for keyIndex = 1, limit do
			display = display .. '|t' .. opponentIndex .. shortKey .. keyIndex .. '='
		end
	end

	return display
end

return WikiCopyPaste
