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

---@class WildriftMatch2CopyPaste: Match2CopyPasteBase
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
	local kda = Logic.readBool(args.kda)

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, bans, kda)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param bans boolean
---@param kda boolean
---@return string
function WikiCopyPaste._getMapCode(mapIndex, bans, kda)
	local lines = {
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=|team2side=|length=|winner=',
		INDENT .. INDENT .. '<!-- Champion/Hero picks -->',
		INDENT .. INDENT .. '|t1c1=|t1c2=|t1c3=|t1c4=|t1c5=',
		INDENT .. INDENT .. '|t2c1=|t2c2=|t2c3=|t2c4=|t2c5=',
	}

	if bans then
		Array.appendWith(lines,
			INDENT .. INDENT .. '<!-- Champion/Hero bans -->',
			INDENT .. INDENT .. '|t1b1=|t1b2=|t1b3=|t1b4=|t1b5=',
			INDENT .. INDENT .. '|t2b1=|t2b2=|t2b3=|t2b4=|t2b5='
		)
	end

	if kda then
		Array.appendWith(lines,
			INDENT .. INDENT .. '<!-- KDA -->',
			INDENT .. INDENT .. '|t1kda1=|t1kda2=|t1kda3=|t1kda4=|t1kda5=',
			INDENT .. INDENT .. '|t2kda1=|t2kda2=|t2kda3=|t2kda4=|t2kda5='
		)
	end
	Array.appendWith(lines, INDENT .. '}}')

	return table.concat(lines, '\n')

end

return WikiCopyPaste
