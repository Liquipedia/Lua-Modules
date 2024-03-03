---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local BaseCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))

---@class WorldofTanksMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.readBool(args.score)
	local mapVeto = Logic.readBool(args.mapVeto)
	local streams = Logic.readBool(args.streams)

	local lines = Array.extend(
		'{{Match',
		INDENT .. '|date=|finished=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
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

	local score = showScore and '|score1=|score2=' or ''

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		local firstMapLine = INDENT .. '|map' .. mapIndex .. '={{Map|map=' .. score  .. '|finished='
	end)

	Array.appendWith(lines, INDENT .. '}}')

	return table.concat(lines, '\n')
end

return WikiCopyPaste
