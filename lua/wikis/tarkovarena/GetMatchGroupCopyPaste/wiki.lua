---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class TarkovArenaMatch2CopyPaste: Match2CopyPasteBase
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

	return table.concat(lines, '\n')
end

return WikiCopyPaste
