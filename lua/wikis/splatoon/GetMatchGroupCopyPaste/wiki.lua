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

---@class SplatoonMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

local VETOES = {
	[0] = '',
	'ban,ban,ban,ban,decider',
	'ban,ban,ban,pick,ban',
	'ban,ban,pick,ban,decider',
	'ban,ban,pick,pick,ban',
	'ban,pick,ban,pick,decider',
	'ban,ban,pick,pick,ban',
	'ban,pick,pick,pick,decider',
	'pick,pick,pick,pick,ban',
	'pick,pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local mapVeto = Logic.readBool(args.mapVeto)
	local displayScore = Logic.nilOr(Logic.readBool(args.score), true)

	local lines = Array.extend(
		'{{Match',
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, displayScore)
		end),
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|twitch= |youtube=',
			INDENT .. '|mvp='
		} or nil,
		Array.map(Array.range(1, bestof), function (i)
			return INDENT .. '|vodgame'.. i ..'='
		end),
		(mapVeto and VETOES[bestof]) and {
			INDENT .. '|mapveto={{MapVeto',
			INDENT .. INDENT .. '|firstpick=',
			INDENT .. INDENT .. '|types=' .. VETOES[bestof],
			INDENT .. INDENT .. '|t1map1=|t2map1=',
			INDENT .. INDENT .. '|t1map2=|t2map2=',
			INDENT .. INDENT .. '|t1map3=|t2map3=',
			INDENT .. INDENT .. '|decider=',
			INDENT .. '}}'
		} or nil,
		Array.flatMap(Array.range(1, bestof), function (i)
			return {
				INDENT .. '|map' .. i .. '={{Map',
				INDENT .. INDENT .. '|map=|maptype=',
				INDENT .. INDENT .. '|t1w1= |t1w2= |t1w3= |t1w4=',
				INDENT .. INDENT .. '|t2w1= |t2w2= |t2w3= |t2w4=',
				INDENT .. INDENT .. '|score1=|score2=|winner=',
				INDENT .. '}}'
			}
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

return WikiCopyPaste
