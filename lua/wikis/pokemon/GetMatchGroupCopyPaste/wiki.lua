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

---@class PokemonMatch2CopyPaste: Match2CopyPasteBase
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
			INDENT .. '|date=',
			INDENT .. '|twitch= |youtube=',
			INDENT .. '|vod=',
		} or nil,
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
function WikiCopyPaste._getMapCode(mapIndex, bans)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=',
		INDENT .. INDENT .. '|t1h1= |t1h2= |t1h3= |t1h4= |t1h5=',
		bans and (INDENT .. INDENT .. '|t1b1= |t1b2= ') or nil,
		INDENT .. INDENT .. '|team2side=',
		INDENT .. INDENT .. '|t2h1= |t2h2= |t2h3= |t2h4= |t2h5=',
		bans and (INDENT .. INDENT .. '|t2b1= |t2b2= ') or nil,
		INDENT .. INDENT .. '|score1= |score2= |winner=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
