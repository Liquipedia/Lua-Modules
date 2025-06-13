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

---@class HeroesMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBool(args.score), true)
	local bans = Logic.readBool(args.bans)
	local veto = Logic.readBool(args.veto)
	local vetoBanRounds = tonumber(args.vetoBanRounds) or 0
	local casters = tonumber(args.casters) or 0

	local lines = Array.extend(
		'{{Match',
		bestof ~= 0 and (INDENT .. '|bestof=' .. bestof) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|twitch=',
		} or nil,
		casters > 0 and {
			INDENT .. table.concat(Array.map(Array.range(1, casters), function(casterIndex)
				return '|caster' .. casterIndex .. '='
			end), ' ')
		} or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		(veto and bestof > 0) and WikiCopyPaste._getVeto(bestof, vetoBanRounds) or nil,
		Array.map(Array.range(1, bestof), function (mapIndex)
			return INDENT .. '|map' .. mapIndex .. WikiCopyPaste._getMap(bans)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@private
---@param bestof integer
---@param vetoRounds integer
---@return string[]
function WikiCopyPaste._getVeto(bestof, vetoRounds)
	local preFilledVetoTypes = string.rep('ban,', vetoRounds)
		.. string.rep('pick,', bestof - 1) .. 'pick'

	return Array.extend(
		INDENT .. '|mapveto={{MapVeto',
		INDENT .. INDENT .. '|format=By turns',
		INDENT .. INDENT .. '|firstpick=',
		INDENT .. INDENT .. '|types=' .. preFilledVetoTypes,
		Array.map(Array.range(1, vetoRounds + bestof), function (round)
			return INDENT .. INDENT .. '|t1map' .. round .. '=|t2map' .. round .. '='
		end),
		INDENT .. '}}'
	)
end

---@private
---@param showBans boolean
---@return string
function WikiCopyPaste._getMap(showBans)
	local lines = Array.extend(
		'={{Map|map=',
		INDENT .. INDENT .. '|team1side=blue |team2side=red |winner=',
		INDENT .. INDENT .. '|vod= |length=',
		INDENT .. INDENT .. '<!-- Hero picks -->',
		INDENT .. INDENT .. '|t1h1= |t1h2= |t1h3= |t1h4= |t1h5=',
		INDENT .. INDENT .. '|t2h1= |t2h2= |t2h3= |t2h4= |t2h5='
	)
	if showBans then
		Array.appendWith(lines,
			INDENT .. INDENT .. '<!-- Hero bans -->',
			INDENT .. INDENT .. '|t1b1=|t1b2=|t1b3=',
			INDENT .. INDENT .. '|t2b1=|t2b2=|t2b3='
		)
	end
	Array.appendWith(lines, INDENT .. '}}')
	return table.concat(lines, '\n')
end

return WikiCopyPaste
