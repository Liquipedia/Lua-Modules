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

---@class EaSportsFcMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)
	local hasSubmatches = Logic.readBool(args.hasSubmatches)

	local lines = Array.extend(
		'{{Match|finished=',
		bestof ~= 0 and (INDENT .. '|bestof=' .. bestof) or nil,
		hasSubmatches and INDENT .. '|hasSubmatches=1' or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|youtube=|twitch='} or {},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '=' .. WikiCopyPaste._getMap(hasSubmatches)
		end) or nil,
		'}}'
	)
	return table.concat(lines, '\n')
end

--subfunction used to generate code for the Map template, depending on the type of opponent
---@private
---@param hasSubmatches boolean
---@return string
function WikiCopyPaste._getMap(hasSubmatches)
	local lines = Array.extend(
		'{{Map',
		INDENT .. INDENT .. '|score1= |score2=',
		hasSubmatches and {
			INDENT .. INDENT .. '|penaltyScore1= |penaltyScore2=',
			INDENT .. INDENT .. '|t1p1= |t1p2= |t2p1= |t2p2='
		} or {
			INDENT .. INDENT .. '|penalty='
		},
		INDENT .. '}}'
	)
	return table.concat(lines, '\n')
end

return WikiCopyPaste
