---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

-- WikiSpecific Code for MatchList and Bracket Code Generators
---@class ApexLegendsMatchCopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

--allowed opponent types on the wiki
local MODES = {
	['solo'] = 'solo',
	['team'] = 'team',
}

--default opponent type (used if the entered mode is not found in the above table)
local DEFAULT_MODE = 'team'

--returns the cleaned opponent type
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DEFAULT_MODE
end

--returns the Code for a Match, depending on the input
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '    '

	local lines = Array.extend(
		'{{Match|finished=',
		indent ..
		'|p_kill=1 |p1=12 |p2=9 |p3=7 |p4=5 |p5=4 |p6=3 |p7=3 |p8=2 |p9=2 |p10=2 |p11=1 |p12=1 |p13=1 |p14=1 |p15=1',
		{indent .. '|twitch=|youtube='}
	)

	if bestof ~= 0 then
		for i = 1, bestof do
			Array.appendWith(lines,
				indent .. '|map' .. i ..
				'={{Map|date=|finished=|map=|vod=|stats=}}'
			)
		end
	end

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode, bestof))
	end

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function WikiCopyPaste._getOpponent(mode, mapCount)
	local out

	local mapScores = table.concat(Array.map(Array.range(1, mapCount), function(idx)
		return '|m' .. idx .. '={{MS||}}'
	end))

	if mode == 'solo' then
		out = '{{SoloOpponent||flag=' .. mapScores .. '}}'
	elseif mode == 'team' then
		out = '{{TeamOpponent|' .. mapScores .. '}}'
	elseif mode == 'literal' then
		out = '{{Literal|}}'
	end

	return out
end

return WikiCopyPaste
