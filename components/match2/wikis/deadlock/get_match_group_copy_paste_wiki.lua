---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class DeadlockMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil, bestof == 0)

	local lines = Array.extend(
		'{{Match|bestof=' .. (bestof ~= 0 and bestof or ''),
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|date=|finished=',
		INDENT .. '|twitch=|youtube=|vod=',
		Array.map(Array.range(1, bestof), WikiCopyPaste._getMapCode),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map|length=|winner=|vod=',
		INDENT .. INDENT .. '|team1side=|team2side=',
		INDENT .. INDENT .. '|t1h1=|t1h2=|t1h3=|t1h4=|t1h5=|t1h6=',
		INDENT .. INDENT .. '|t2h1=|t2h2=|t2h3=|t2h4=|t2h5=|t2h6=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
