---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class OverwatchMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBool(args.score), bestof == 0)
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)


	local lines = Array.extendWith({},
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and (INDENT .. '|winner=') or nil,
		INDENT .. '|date=',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		Logic.readBool(args.streams) and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		bestof ~= 0 and Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|mode=|score1=|score2=|winner=}}'
		end) or nil,
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

---@param template string
---@param id string
---@param modus string
---@param args table
---@return string
---@return table
function WikiCopyPaste.getStart(template, id, modus, args)
	args.namedMatchParams = false
	args.headersUpTop = Logic.readBool(Logic.emptyOr(args.headersUpTop, true))

	local start = '{{' .. WikiCopyPaste.getMatchGroupTypeCopyPaste(modus, template) .. '|id=' .. id

	args.customHeader = false

	return start, args
end

return WikiCopyPaste
