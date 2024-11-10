---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class MobileLegendsMatch2CopyPaste: Match2CopyPasteBase
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
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date= |youtube=',
			args.vod == 'series' and (INDENT .. '|vod=') or nil,
		} or nil,
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, bans, args.vod)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param bans boolean
---@param vod string
---@return string
function WikiCopyPaste._getMapCode(mapIndex, bans, vod)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map' ..  (vod == 'maps' and '|vod=' or ''),
		INDENT .. INDENT .. '|team1side= |team2side= |length= |winner=',
		INDENT .. INDENT .. '<!-- Hero picks -->',
		INDENT .. INDENT .. '|t1h1= |t1h2= |t1h3= |t1h4= |t1h5=',
		INDENT .. INDENT .. '|t2h1= |t2h2= |t2h3= |t2h4= |t2h5=',
		bans and (INDENT .. INDENT .. '<!-- Hero bans -->') or nil,
		bans and (INDENT .. INDENT .. '|t1b1= |t1b2= |t1b3= |t1b4= |t1b5=') or nil,
		bans and (INDENT .. INDENT .. '|t1b1= |t1b2= |t1b3= |t1b4= |t1b5=') or nil,
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
