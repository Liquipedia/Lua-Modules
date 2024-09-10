---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class RainbowsixMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

local VETOES = {
	[0] = '',
	[1] = 'ban,ban,ban,ban,decider',
	[2] = 'ban,ban,ban,pick,ban',
	[3] = 'ban,ban,pick,ban,decider',
	[4] = 'ban,ban,pick,pick,ban',
	[5] = 'ban,pick,ban,pick,decider',
	[6] = 'ban,ban,pick,pick,ban',
	[7] = 'ban,pick,pick,pick,decider',
	[8] = 'pick,pick,pick,pick,ban',
	[9] = 'pick,pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local casters = Logic.readBool(args.casters)
	local mapDetails = Logic.readBool(args.detailedMap)
	local mapDetailsOT = Logic.readBool(args.detailedMapOT)
	local mapScore = Logic.readBool(args.mapScore)
	local mapVeto = Logic.readBool(args.mapVeto)
	local matchLinks = args.matchLinks and Array.unique(Array.parseCommaSeparatedString(args.matchLinks)) or {}
	local mvps = Logic.readBool(args.mvp)
	local showScore = Logic.readBool(args.score)
	local streams = Logic.readBool(args.streams)

	---@param list string[]
	---@param indents integer
	---@return string?
	local buildListLine = function(list, indents)
		if #list == 0 then return nil end

		return string.rep(INDENT, indents) .. table.concat(Array.map(list, function(elemenmt)
			return '|' .. elemenmt:lower() .. '='
		end))
	end

	local lines = Array.extend(
		'{{Match',
		INDENT .. '|date=|finished=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		buildListLine(matchLinks, 1),
		casters and (INDENT .. '|caster1=|caster2=') or nil,
		mvps and (INDENT .. '|mvp=') or nil,
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
			INDENT .. INDENT .. '|t1map4=|t2map4=',
			INDENT .. INDENT .. '|decider=',
			INDENT .. '}}'
		)
	end

	local score = mapScore and '|score1=|score2=' or ''
	local atkDefParams = function(opponentIndex)
		local prefix = '|t' .. opponentIndex
		return table.concat(Array.extend(
			INDENT .. INDENT .. prefix .. 'atk=' .. prefix .. 'def=',
			mapDetailsOT and (prefix .. 'otatk=' .. prefix .. 'otdef=') or nil
		))
	end

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		local firstMapLine = INDENT .. '|map' .. mapIndex .. '={{Map|map=' .. score .. '|finished='
		if not mapDetails then
			Array.appendWith(lines, firstMapLine .. '}}')
			return
		end

		Array.appendWith(lines,
			firstMapLine,
			INDENT .. INDENT .. '|t1ban1=|t1ban2=',
			INDENT .. INDENT .. '|t2ban1=|t2ban2=',
			INDENT .. INDENT .. '|t1firstside=' .. (mapDetailsOT and '|t1firstsideot=' or ''),
			atkDefParams(1),
			atkDefParams(2),
			INDENT .. '}}'
		)
	end)

	Array.appendWith(lines, INDENT .. '}}')

	return table.concat(lines, '\n')
end

return WikiCopyPaste
