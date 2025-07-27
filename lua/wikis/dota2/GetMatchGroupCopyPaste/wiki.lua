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

---@class Dota2Match2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = ''

--returns the Code for a Match, depending on the input
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil, bestof == 0)
	local generateMatchPage = Logic.readBool(args.generateMatchPage)

	local lines = Array.extend(
		'{{Match',
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|finished=',
			INDENT .. '|twitch='
		} or nil,
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|vodgame'.. mapIndex ..'='
		end),
		generateMatchPage and {} or Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|matchid'.. mapIndex ..'='
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, Logic.readBool(args.bans), generateMatchPage)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param bans boolean
---@param generateMatchPage boolean
---@return string
function WikiCopyPaste._getMapCode(mapIndex, bans, generateMatchPage)
	if Logic.readBool(generateMatchPage) then
		return INDENT .. '|map' .. mapIndex .. '={{ApiMap|matchid=|reversed=}}'
	end
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=',
		INDENT .. INDENT .. '|t1h1=|t1h2=|t1h3=|t1h4=|t1h5=',
		bans and (INDENT .. INDENT .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=|t1b6=|t1b7=') or nil,
		INDENT .. INDENT .. '|team2side=',
		INDENT .. INDENT .. '|t2h1=|t2h2=|t2h3=|t2h4=|t2h5=',
		bans and (INDENT .. INDENT .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5=|t2b6=|t2b7=') or nil,
		INDENT .. INDENT .. '|length=|winner=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
