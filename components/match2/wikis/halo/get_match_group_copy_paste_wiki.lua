---
-- @Liquipedia
-- wiki=halo
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class HaloMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBoolOrNil(args.score), bestof == 0)

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		args.needsWinner == 'true' and INDENT .. '|winner=' or nil,
		args.hasDate == 'true' and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|mode=|score1=|score2=|winner=}}'
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
