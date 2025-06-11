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

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---WikiSpecific Code for MatchList and Bracket Code Generators
---@class FightersMatchCopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)

	local lines = Array.extend(
		'{{Match|bestof=' .. bestof,
		Logic.readBool(args.date) and INDENT .. '|date=' or nil,
		Logic.readBool(args.vod) and INDENT .. '|twitch=|vod=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Logic.readBool(args.details) and Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. WikiCopyPaste._getMap(mode)
		end) or nil,
		'}}'
	)

	return table.concat(lines, '\n')
end

--subfunction used to generate code for the Map template, depending on the type of opponent
---@param mode string
---@return string
function WikiCopyPaste._getMap(mode)
	local lines = Array.extend(
		'={{Map',
		mode == Opponent.team and INDENT .. INDENT .. '|t1p1=|t2p1=' or nil,
		INDENT .. INDENT .. '|o1p1={{Chars|}}|o2p1={{Chars|}}',
		INDENT .. INDENT .. '|score1=|score2=|winner=',
		INDENT .. '}}'
	)
	return table.concat(lines, '\n')
end

return WikiCopyPaste
