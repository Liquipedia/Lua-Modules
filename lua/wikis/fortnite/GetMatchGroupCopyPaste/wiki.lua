---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---@class FortniteMatchCopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if opponents > 2 then
		return WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	else
		return WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	end
end

---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	local showScore = bestof == 0

	local lines = Array.extend(
		'{{Match',
		showScore and (INDENT .. '|finished=') or nil,
		{INDENT .. '|date='},
		{INDENT .. '|twitch=|youtube='},
		{INDENT .. '|vod='},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|score1=|score2=|finished=}}'
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	local defaultScoring = '|p1= |p2= |p3= |p4= |p5= |p6= |p7= |p8= |p9= |p10= |p11= |p12= |p13= |p14= |p15= |p_kill=4'
	if mode == Opponent.duo then
		defaultScoring = '|p1=65|p2=56|p3=52|p4=48|p5=44|p6=40|p7=38|p8=36|p9=34|p10=32|p11=30|p12=28|p13=26|p14=24' ..
			'|p15=22|p16=20|p17=18|p18=16|p19=14|p20=12|p21=10|p22=8|p23=6|p24=4|p25=2|p_kill=4'
	elseif mode == Opponent.trio or mode == Opponent.team then
		defaultScoring = '|p1=65|p2=54|p3=48|p4=44|p5=40|p6=36|p7=33|p8=30|p9=27|p10=24|p11=21|p12=18|p13=15|p14=12'..
			'|p15=9|p16=6|p17=3|p_kill=4'
	end

	local lines = Array.extend(
		'{{Match|finished=',
		INDENT .. defaultScoring,
		{INDENT .. '|twitch=|youtube='},
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|date=|finished=|map=|vod=}}'
		end),
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getFfaOpponent(mode, bestof)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mode string
---@param mapCount integer
---@return string
function WikiCopyPaste.getFfaOpponent(mode, mapCount)
	local mapScores = table.concat(Array.map(Array.range(1, mapCount), function(idx)
		return '|m' .. idx .. '={{MS||}}'
	end))

	if mode == Opponent.solo then
		return '{{SoloOpponent||flag=' .. mapScores .. '}}'
	elseif mode == Opponent.duo then
		return '{{2Opponent|' .. mapScores .. '}}'
	elseif mode == Opponent.trio then
		return '{{3Opponent|' .. mapScores .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|' .. mapScores .. '}}'
	elseif mode == Opponent.literal then
		return '{{Literal|' .. mapScores .. '}}'
	end

	return ''
end

return WikiCopyPaste
