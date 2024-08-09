---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')
local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

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
		bans and '|t1bans={{Cards|}}|t2bans={{Cards|}}' or nil
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
