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

---@class SideswipeMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---@private
---@return string
function WikiCopyPaste._getMap()
	return table.concat({
		'{{Map',
		INDENT .. INDENT .. '|map=',
		INDENT .. INDENT .. '|score1=|score2=',
		INDENT .. INDENT .. '|ot=|otlength=',
		INDENT .. INDENT .. '|vod=',
		INDENT .. '}}'
	}, '\n')
end

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)

	local lines = Array.extend({},
		'{{Match',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|finished=',
		INDENT .. '|date=',
		Array.map(Array.range(1, bestof), function (mapIndex)
			return INDENT .. '|map' .. mapIndex .. '=' .. WikiCopyPaste._getMap()
		end),
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
