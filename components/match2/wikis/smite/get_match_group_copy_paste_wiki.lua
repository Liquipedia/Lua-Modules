---
-- @Liquipedia
-- wiki=smite
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class SmiteMatch2CopyPaste: Match2CopyPasteBase
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
	local bans = Logic.readBool(args.bans)

	local lines = Array.extend(
		'{{Match',
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|youtube=|twitch='} or {},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, bans)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param bans boolean
---@return string
function WikiCopyPaste._getMapCode(mapIndex, bans, kda)
	local lines = {
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=|team2side=|length=|winner=',
		INDENT .. INDENT .. '<!-- God picks -->',
		INDENT .. INDENT .. '|t1g1=|t1g2=|t1g3=|t1g4=|t1g5=',
		INDENT .. INDENT .. '|t2g1=|t2g2=|t2g3=|t2g4=|t2g5=',
	}

	if bans then
		Array.appendWith(lines,
			INDENT .. INDENT .. '<!-- God bans -->',
			INDENT .. INDENT .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=',
			INDENT .. INDENT .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5='
		)
	end
	Array.appendWith(lines, INDENT .. '}}')

	return table.concat(lines, '\n')

end

return WikiCopyPaste
