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

---@class WorldOfWarcraftMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil, bestof == 0)

	local lines = Array.extend(
		'{{Match',
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|date=',
		INDENT .. '|twitch=|youtube=|vod=',
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map|map=',
		INDENT .. INDENT .. '|t1s1=|t1s2=|t1s3=',
		INDENT .. INDENT .. '|t2s1=|t2s2=|t2s3=',
		INDENT .. INDENT .. '|length=|winner=|damp=|vod=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
