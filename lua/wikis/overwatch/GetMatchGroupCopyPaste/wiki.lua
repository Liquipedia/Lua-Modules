---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
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
	local casters = Logic.readBool(args.casters)
	local showScore = Logic.nilOr(Logic.readBool(args.score), bestof == 0)
	local streams = Logic.readBool(args.streams)
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)
	local hasBans = Logic.readBool(args.bans)

	local lines = Array.extendWith({},
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and (INDENT .. '|winner=') or nil,
		INDENT .. '|date=',
		streams and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		casters and (INDENT .. '|caster1=|caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		bestof ~= 0 and Array.map(Array.range(1, bestof), FnUtil.curry(WikiCopyPaste._getMapCode, hasBans)) or nil,
		Logic.readBool(args.faceit) and (INDENT .. '|faceit=') or nil,
		Logic.readBool(args.mvp) and (INDENT .. '|mvp=') or nil,
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param hasBans boolean
---@return string
function WikiCopyPaste._getMapCode(hasBans, mapIndex)
	if not hasBans then return INDENT .. '|map' .. mapIndex .. '={{Map|map=|mode=|score1=|score2=|winner=}}' end

	return table.concat({
		INDENT .. '|map' .. mapIndex .. '={{Map|map=|mode=|score1=|score2=|winner=',
		INDENT .. INDENT .. '|t1b1=|t2b1=|banstart=}}',
	}, '\n')
end

return WikiCopyPaste
