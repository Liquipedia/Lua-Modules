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

---@class ChessMatch2CopyPaste: Match2CopyPasteBase
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

	local lines = Array.extend(
		'{{Match',
		showScore and (INDENT .. '|finished=') or nil,
		INDENT .. '|date=',
		Logic.readBool(args.streams) and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		Array.map(Array.range(1, bestof), WikiCopyPaste._map),
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

function WikiCopyPaste._map(mapIndex)
	return table.concat({
		INDENT .. '|map' .. mapIndex .. '={{Map|white=|eco=|length=|winner=',
		INDENT .. INDENT .. '|chesscom=',
		INDENT .. INDENT .. '|chessgames=',
		INDENT .. INDENT .. '|lichess=',
		INDENT .. '}}',
	}, '\n')
end

return WikiCopyPaste
