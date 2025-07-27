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

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---WikiSpecific Code for MatchList and Bracket Code Generators
---@class AgeOfEmpiresMatchCopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local isFfa = Logic.readBool(args.ffa)

	local lines = Array.extend(
		'{{Match',
		INDENT .. '|date=',
		INDENT .. '|bestof=' .. bestof,
		INDENT .. '|twitch=|vod=',
		not isFfa and (INDENT .. '|mapdraft=|civdraft=') or nil,
		isFfa and Logic.readBool(args.hasPointsMapping)
			and (INDENT .. WikiCopyPaste._getPointsMapping(opponents)) or nil,
		Logic.readBool(args.casters) and (INDENT .. '|caster1= |caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' ..
				(isFfa and WikiCopyPaste.getFfaOpponent(mode, bestof) or WikiCopyPaste.getOpponent(mode))
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. WikiCopyPaste._getMap(mode, isFfa)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@return string
function WikiCopyPaste.getOpponent(mode)
	if mode == Opponent.solo then
		return '{{SoloOpponent|}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

---@param mode string
---@param mapCount integer
---@return string
function WikiCopyPaste.getFfaOpponent(mode, mapCount)
	local mapArgs = table.concat(
		Array.map(Array.range(1, mapCount), function (index)
			return '|m' .. index .. '={{MS||civs=}}'
		end)
	)

	local opponent = WikiCopyPaste.getOpponent(mode)
		:gsub('}}', mapArgs .. '}}')
	return opponent
end

--subfunction used to generate code for the Map template, depending on the type of opponent
---@param mode string
---@param isFfa boolean
---@return string
function WikiCopyPaste._getMap(mode, isFfa)
	local opponentLines = isFfa and {
		INDENT .. INDENT .. '|date=',
	} or {
		mode == Opponent.team and INDENT .. INDENT .. '|players1=' or nil,
		INDENT .. INDENT .. '|civs1=',
		mode == Opponent.team and INDENT .. INDENT .. '|players2=' or nil,
		INDENT .. INDENT .. '|civs2=',
	}

	local lines = Array.extend(
		'={{Map',
		INDENT .. INDENT .. '|map=' .. (not isFfa and '|winner=' or ''),
		Array.extractValues(opponentLines),
		INDENT .. '}}'
	)
	return table.concat(lines, '\n')
end

---@param opponents integer
---@return string
function WikiCopyPaste._getPointsMapping(opponents)
	return table.concat(
		Array.map(Array.range(1, opponents), function (index)
			return '|p' .. index .. '='
		end)
	)
end

return WikiCopyPaste
