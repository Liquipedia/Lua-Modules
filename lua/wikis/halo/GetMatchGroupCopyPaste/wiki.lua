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
	if opponents > 2 then
		return WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	else
		return WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	end
end

---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getStandardMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil(args.score), bestof == 0)

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
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

---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getFfaMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend(
		'{{Match|finished=',
		INDENT .. '|p_kill=1 |p1=0',
		INDENT .. '|twitch=|youtube=',
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|date=|finished=|vod=}}'
		end),
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getFfaOpponent(mode, bestof)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
