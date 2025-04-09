---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

--[[

WikiSpecific Code for MatchList and Bracket Code Generators

]]--

---@class SplatoonMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local VETOES = {
	[0] = '',
	'ban,ban,ban,ban,decider',
	'ban,ban,ban,pick,ban',
	'ban,ban,pick,ban,decider',
	'ban,ban,pick,pick,ban',
	'ban,pick,ban,pick,decider',
	'ban,ban,pick,pick,ban',
	'ban,pick,pick,pick,decider',
	'pick,pick,pick,pick,ban',
	'pick,pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local mapVeto = Logic.readBool(args.mapVeto)
	local indent = '  '

	if bestof == 0 and Logic.nilOr(Logic.readBool(args.score), true) then
		args.score = true
	end
	local displayScore = Logic.readBool(args.score)

	local lines = Array.extend(
		'{{Match',
		Logic.readBool(args.needsWinner) and indent .. '|winner=' or nil
	)

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode, displayScore))
	end

	if Logic.readBool(args.hasDate) then
		Array.appendWith(lines,
			indent .. '|date=',
			indent .. '|twitch= |youtube=',
			indent .. '|mvp='
		)
	end

	for i = 1, bestof do
		Array.appendWith(lines, indent .. '|vodgame'.. i ..'=')
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
		Array.appendWith(lines,
			indent .. '|map' .. i .. '={{Map',
			indent .. indent .. '|map=|maptype=',
			indent .. indent .. '|t1w1= |t1w2= |t1w3= |t1w4='
		)

		Array.appendWith(lines,
			indent .. indent .. '|t2w1= |t2w2= |t2w3= |t2w4='
		)

		Array.appendWith(lines,
			indent .. indent .. '|score1=|score2=|winner=',
			indent .. '}}'
		)
	end

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function WikiCopyPaste._getOpponent(mode, displayScore)
	local scoreText = displayScore and '|score=' or ''

	if mode == 'solo' then
		return '{{SoloOpponent||flag=' .. scoreText .. '}}'
	elseif mode == 'team' then
		return '{{TeamOpponent|' .. scoreText .. '}}'
	elseif mode == 'literal' then
		return '{{Literal|}}'
	end
end

return WikiCopyPaste
