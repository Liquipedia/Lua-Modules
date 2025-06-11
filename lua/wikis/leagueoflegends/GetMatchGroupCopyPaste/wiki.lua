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

---@class LeagueoflegendsMatch2CopyPaste: Match2CopyPasteBase
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
	if Logic.readBool(args.bigMatch) then
		return '{{Match}}'
	end

	local showScore = Logic.nilOr(Logic.readBoolOrNil(args.score), bestof == 0)
	local casters = tonumber(args.casters) or 0

	local lines = Array.extend(
		'{{Match|patch=',
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|twitch= |youtube=',
			(Logic.readBool(args.reddit) and INDENT .. '|reddit= |gol=' or nil),
			INDENT .. '|mvp='
		} or nil,
		casters > 0 and {
			INDENT .. table.concat(Array.map(Array.range(1, casters), function(casterIndex)
				return '|caster' .. casterIndex .. '='
			end), ' ')
		} or nil,
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|vodgame'.. mapIndex ..'='
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, args)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param args table
---@return string
function WikiCopyPaste._getMapCode(mapIndex, args)
	if Logic.readBool(args.generateMatchPage) then
		return INDENT .. '|map' .. mapIndex .. '={{ApiMap|matchid=|reversed=}}'
	end
	local bans = Logic.readBool(args.bans)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=',
		INDENT .. INDENT .. '|t1c1= |t1c2= |t1c3= |t1c4= |t1c5=',
		bans and (INDENT .. INDENT .. '|t1b1= |t1b2= |t1b3= |t1b4= |t1b5=') or nil,
		INDENT .. INDENT .. '|team2side=',
		INDENT .. INDENT .. '|t2c1= |t2c2= |t2c3= |t2c4= |t2c5=',
		bans and (INDENT .. INDENT .. '|t2b1= |t2b2= |t2b3= |t2b4= |t2b5=') or nil,
		INDENT .. INDENT .. '|length= |winner=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
