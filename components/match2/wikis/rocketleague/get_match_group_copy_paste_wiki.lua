---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')

local wikiCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

--allowed opponent types on the wiki
local MODES = { ['solo'] = 'solo', ['team'] = 'team' }
local indent = '    '

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = 'team'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
wikiCopyPaste._getMaps = FnUtil.memoize(function(bestof)
	local map = table.concat({
		'{{Map',
		indent .. indent .. '|map=',
		indent .. indent .. '|score1=|score2=',
		indent .. indent .. '|ot=|otlength=',
		indent .. indent .. '|vod=',
		indent .. '}}'
	}, '\n')

	local lines = {}
	for i = 1, bestof do
		table.insert(lines, indent .. '|map' .. i .. '=' .. map)
	end
	Array.appendWith(lines,
		indent .. '|finished=',
		indent .. '|date=',
		''
	)

	return table.concat(lines, '\n')
end)

--returns the Code for a Match, depending on the input
--for more customization please change stuff here^^
function wikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local out = tostring(mw.message.new('BracketConfigMatchTemplate'))
	if out == '⧼BracketConfigMatchTemplate⧽' then
		local opponentLines = {}
		for i = 1, opponents do
			table.insert(opponentLines, indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode))
		end

		local lines = Array.extend({
			'{{Match',
			opponentLines,
			indent .. '|finished=',
			indent .. '|tournament=',
			'}}',
			''
		})
		return table.concat(lines, '\n')
	else
		out = out:gsub('<nowiki>', '')
		out = out:gsub('</nowiki>', '')
		for i = 1, opponents do
			out = out:gsub('[ \t]*|opponent' .. i .. '=' , indent .. '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode))
		end

		out = out:gsub('[ \t]*|map1=.*\n' , '<<maps>>')
			:gsub('[ \t]*|map%d+=.*\n' , '')
			:gsub('<<maps>>' , wikiCopyPaste._getMaps(bestof))

		return out .. '\n'
	end
end

return wikiCopyPaste
