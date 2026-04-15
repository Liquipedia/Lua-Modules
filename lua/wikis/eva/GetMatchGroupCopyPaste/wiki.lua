---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class EvaArenaMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = bestof == 0
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)

	local lines = Array.extendWith({},
		'{{Match',
		showScore and (INDENT .. '|finished=') or nil,
		INDENT .. '|date=',
		Logic.readBool(args.streams) and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		bestof ~= 0 and Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|score1=|score2=|winner=}}'
		end) or nil,
		INDENT .. '}}'
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

	return table.concat(lines, '\n')
end

return WikiCopyPaste
