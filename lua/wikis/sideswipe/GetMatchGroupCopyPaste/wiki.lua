---
-- @Liquipedia
-- wiki=sideswipe
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class SideswipeMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

--allowed opponent types on the wiki
local MODES = { ['solo'] = 'solo', ['team'] = 'team' }
local INDENT = WikiCopyPaste.Indent

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = 'team'

--returns the cleaned opponent type
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
WikiCopyPaste._getMaps = FnUtil.memoize(function(bestof)
	local map = table.concat({
		'{{Map',
		INDENT .. INDENT .. '|map=',
		INDENT .. INDENT .. '|score1=|score2=',
		INDENT .. INDENT .. '|ot=|otlength=',
		INDENT .. INDENT .. '|vod=',
		INDENT .. '}}'
	}, '\n')

	local lines = {}
	for i = 1, bestof do
		table.insert(lines, INDENT .. '|map' .. i .. '=' .. map)
	end
	Array.appendWith(lines,
		INDENT .. '|finished=',
		INDENT .. '|date=',
		''
	)

	return table.concat(lines, '\n')
end)

--returns the Code for a Match, depending on the input
--for more customization please change stuff here^^
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local out = tostring(mw.message.new('BracketConfigMatchTemplate'))
	if out == '⧼BracketConfigMatchTemplate⧽' then
		local opponentLines = {}
		for i = 1, opponents do
			table.insert(opponentLines, INDENT .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode))
		end

		local lines = Array.extend({
			'{{Match',
			opponentLines,
			INDENT .. '|finished=',
			INDENT .. '|tournament=',
			'}}',
			''
		})
		return table.concat(lines, '\n')
	else
		out = out:gsub('<nowiki>', '')
		out = out:gsub('</nowiki>', '')
		for i = 1, opponents do
			out = out:gsub('[ \t]*|opponent' .. i .. '=' , INDENT .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode))
		end

		out = out:gsub('[ \t]*|map1=.*\n' , '<<maps>>')
			:gsub('[ \t]*|map%d+=.*\n' , '')
			:gsub('<<maps>>' , WikiCopyPaste._getMaps(bestof))

		return out .. '\n'
	end
end

return WikiCopyPaste
