---
-- @Liquipedia
-- wiki=ageofempires
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
	local isFFA = Logic.readBool(args.ffa)

	local lines = Array.extend(
		'{{Match',
		INDENT .. '|date=',
		INDENT .. '|bestof=' .. bestof,
		INDENT .. '|twitch=|vod=',
		not isFFA and (INDENT .. '|mapdraft=|civdraft=') or nil,
		isFFA and Logic.readBool(args.hasPointsMapping)
			and (INDENT .. WikiCopyPaste._getPointsMapping(opponents)) or nil,
		Logic.readBool(args.casters) and (INDENT .. '|caster1= |caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode, bestof, isFFA)
		end),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. WikiCopyPaste._getMap(mode, isFFA)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@param bestof integer
---@param isFFA boolean
---@return string
function WikiCopyPaste._getOpponent(mode, bestof, isFFA)
	local additionalContent = ''

	if isFFA then
		additionalContent = table.concat(
			Array.map(Array.range(1, bestof), function (index)
				return '|m' .. index .. '={{MS||civs=}}'
			end)
		)
	end

	if mode == Opponent.solo then
		return '{{SoloOpponent|' .. additionalContent .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

--subfunction used to generate code for the Map template, depending on the type of opponent
---@param mode string
---@param isFFA boolean
---@return string
function WikiCopyPaste._getMap(mode, isFFA)
	local opponentLines = not isFFA and {
		mode == Opponent.team and INDENT .. INDENT .. '|players1=' or nil,
		INDENT .. INDENT .. '|civs1=',
		mode == Opponent.team and INDENT .. INDENT .. '|players2=' or nil,
		INDENT .. INDENT .. '|civs2=',
	} or {
		INDENT .. INDENT .. '|date=',
	}

	local lines = Array.extend(
		'={{Map',
		INDENT .. INDENT .. '|map=' .. (not isFFA and '|winner=' or ''),
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
