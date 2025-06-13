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

---@class PaladinsMatch2CopyPaste: Match2CopyPasteBase
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

	local lines = Array.extend(
		'{{Match2',
		Logic.readBool(args.showScore) and INDENT .. '|finished=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|date= |twitch= |youtube= |vod=',
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex)
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map|map=',
		INDENT .. INDENT .. '|t1c1= |t1c2= |t1c3= |t1c4= |t1c5=',
		INDENT .. INDENT .. '|t2c1= |t2c2= |t2c3= |t2c4= |t2c5=',
		INDENT .. INDENT .. '|winner= |score1= |score2=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
