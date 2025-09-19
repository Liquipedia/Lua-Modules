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

---@class MarvelRivalsMatch2CopyPaste: Match2CopyPasteBase
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
	local casters = Logic.readBool(args.casters)
	local showScore = bestof == 0
	local streams = Logic.readBool(args.streams)
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)

	local lines = Array.extendWith({},
		'{{Match',
		showScore and (INDENT .. '|finished=') or nil,
		INDENT .. '|date=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		casters and (INDENT .. '|caster1=|caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		bestof ~= 0 and Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|score1=|score2=|winner=}}'
		end) or nil,
		Logic.readBool(args.mvp) and (INDENT .. '|mvp=') or nil,
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
