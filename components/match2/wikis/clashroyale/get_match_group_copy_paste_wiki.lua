---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---@class ClashroyaleMatch2CopyPaste: Match2CopyPasteBase
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
	local bans = Logic.readBool(args.bans)
	local mvps = Logic.readBool(args.mvp)
	local needsWinner = Logic.readBool(args.needsWinner)
	local streams = Logic.readBool(args.streams)
	local showScore = Logic.readBool(args.score) or bestof == 0

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		needsWinner and (INDENT .. '|winner=') or nil,
		INDENT .. '|date=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		mvps and (INDENT .. '|mvp=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		bans and '|t1bans={{Cards|}}|t2bans={{Cards|}}' or nil,
		Array.map(Array.range(1, bestof), FnUtil.curry(WikiCopyPaste.getMapCode, mode)),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mode any
---@param mapIndex any
---@return string?
function WikiCopyPaste.getMapCode(mode, mapIndex)
	if mode == Opponent.solo then
		return table.concat({
			INDENT .. '|map' .. mapIndex .. '={{Map|winner=',
			INDENT .. INDENT .. '<!-- Card picks -->',
			INDENT .. INDENT .. '|t1p1c={{Cards| | | | | | | | }}',
			INDENT .. INDENT .. '|t2p1c={{Cards| | | | | | | | }}',
			INDENT .. '}}',
		}, '\n')
	elseif mode == Opponent.duo then
		return table.concat({
			INDENT .. '|map' .. mapIndex .. '={{Map|winner=',
			INDENT .. INDENT .. '<!-- Card picks -->',
			INDENT .. INDENT .. '|t1p1c={{Cards| | | | | | | | }}',
			INDENT .. INDENT .. '|t1p2c={{Cards| | | | | | | | }}',
			INDENT .. INDENT .. '|t2p1c={{Cards| | | | | | | | }}',
			INDENT .. INDENT .. '|t2p2c={{Cards| | | | | | | | }}',
			INDENT .. '}}',
		}, '\n')
	elseif mode == Opponent.team then
		return table.concat({
			INDENT .. '|map' .. mapIndex .. '={{Map|winner=|subgroup=',
			INDENT .. INDENT .. '<!-- Players -->',
			INDENT .. INDENT .. '|t1p1=',
			INDENT .. INDENT .. '|t2p1=',
			INDENT .. '}}',
		}, '\n')
	end
	return nil
end

return WikiCopyPaste
