---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class ValorantMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

local VETOES = {
	[0] = '',
	[1] = 'ban,ban,ban,decider',
	[2] = 'ban,ban,pick,ban',
	[3] = 'ban,pick,ban,decider',
	[4] = 'ban,pick,pick,ban',
	[5] = 'ban,pick,pick,decider',
	[6] = 'pick,pick,pick,ban',
	[7] = 'pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if Logic.readBool(args.matchPage) then
		return '{{Match}}'
	end

	local showScore = Logic.readBool(args.score)
	local mapVeto = Logic.readBool(args.mapVeto)
	local streams = Logic.readBool(args.streams)
	local lines = Array.extend(
		'{{Match',
		index == 1 and Logic.readBool(args.matchsection) and (INDENT .. '|matchsection=') or nil,
		INDENT .. '|date=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		Logic.readBool(args.casters) and (INDENT .. '|caster1= |caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end)
	)

	if mapVeto and VETOES[bestof] then
		Array.appendWith(lines,
			INDENT .. '|mapveto={{MapVeto',
			INDENT .. INDENT .. '|firstpick=',
			INDENT .. INDENT .. '|types=' .. VETOES[bestof],
			INDENT .. INDENT .. '|t1map1=|t2map1=',
			INDENT .. INDENT .. '|t1map2=|t2map2=',
			INDENT .. INDENT .. '|t1map3=|t2map3=',
			INDENT .. INDENT .. '|decider=',
			INDENT .. '}}'
		)
	end

	Array.extendWith(lines, Array.map(Array.range(1, bestof), FnUtil.curry(WikiCopyPaste._getMap, args)))

	Array.appendWith(lines,'}}')

	return table.concat(lines, '\n')
end

---@private
---@param args table
---@param mapIndex integer
---@return string
function WikiCopyPaste._getMap(args, mapIndex)
	if Logic.readBool(args.generateMatchPage) then
		return table.concat({
			INDENT .. '|map' .. mapIndex .. '={{ApiMap',
			INDENT .. INDENT .. '|matchid=',
			INDENT .. INDENT .. '|reversed=',
			INDENT .. INDENT .. '|vod=',
			INDENT .. '}}'
		}, '\n')
	end
	if not Logic.readBool(args.detailedMap) then
		return INDENT .. '|map' .. mapIndex .. '={{Map|map=|score1=|score2=|finished=}}'
	end

	local mapDetailsOT = Logic.readBool(args.detailedMapOT)

	local mapStats = '|t1atk=|t1def='
	if mapDetailsOT then
		mapStats = mapStats .. '|t1otatk=|t1otdef='
	end
	if mapDetailsOT then
		mapStats = mapStats .. '|t2otatk=|t2otdef='
	end

	return table.concat({
		INDENT .. '|map' .. mapIndex .. '={{Map|map=|finished=',
		INDENT .. INDENT .. '|t1firstside=',
		INDENT .. INDENT .. mapStats,
		INDENT .. '}}'
	}, '\n')
end

return WikiCopyPaste
