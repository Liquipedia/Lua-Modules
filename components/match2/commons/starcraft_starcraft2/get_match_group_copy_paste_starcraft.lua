---
-- @Liquipedia
-- wiki=commons
-- page=Module:GetMatchGroupCopyPaste/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

--WikiSpecific Code for MatchList and Bracket Code Generators

---@class Starcraftt2Match2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

--allowed opponent types on the wiki (archon and 2v2 both are of type
--"duo", but they need different code, hence them both being available here)
local MODES = {
	archon = 'archon',
	team = Opponent.team,
	literal = Opponent.literal,
	['1v1'] = Opponent.solo,
	['2v2'] = Opponent.duo,
	['3v3'] = Opponent.trio,
	['4v4'] = Opponent.quad,
	['1'] = Opponent.solo,
	['2'] = Opponent.duo,
	['3'] = Opponent.trio,
	['4'] = Opponent.quad,
}

--default opponent type (used if the entered mode is not found in the above table)
local DefaultMode = Opponent.solo

---returns the cleaned opponent type
---@param mode string?
---@return string
function WikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

---returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil(args.score), bestof == 0)

	local hasSubmatch = Logic.isNumeric(args.submatch) or Logic.readBool(args.submatch)

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
		Logic.readBool(args.casters) and (INDENT .. '|caster1=|caster2=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof),function (mapIndex)
			return INDENT .. '|map' .. mapIndex .. '=' ..
				WikiCopyPaste._getMapCode(mode, mapIndex, hasSubmatch, tonumber(args.submatch))
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mode string
---@param mapIndex integer
---@param hasSubmatch boolean
---@param submatchBestof integer?
---@return string
function WikiCopyPaste._getMapCode(mode, mapIndex, hasSubmatch, submatchBestof)
	if mode ~= Opponent.team then
		return '{{Map|map=|winner=}}'
	elseif not hasSubmatch then
		return '{{Map|map=|winner=|t1p1=|t2p1=}}'
	end

	local subMatchNumber = submatchBestof and (math.floor((mapIndex - 1) / submatchBestof) + 1) or ''
	return '{{Map|map=|winner=|t1p1=|t2p1=|subgroup=' .. subMatchNumber .. '}}'
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@param showScore boolean
---@return string
function WikiCopyPaste.getOpponent(mode, showScore)
	local scoreDisplay = showScore and '|score=' or ''
	local partySize = Opponent.partySize(mode)
	if partySize then
		local parts = {'{{' .. mw.getContentLanguage():ucfirst(mode) .. 'Opponent'}
		Array.forEach(Array.range(1, partySize), function(playerIndex)
			table.insert(parts, '|p' .. playerIndex .. '=')
		end)
		return table.concat(Array.append(parts, scoreDisplay .. '}}'))
	end

	if mode == 'archon' then
		return '{{Archon|p1=|p2=|race=' .. scoreDisplay .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|template=' .. scoreDisplay .. '}}'
	elseif mode == Opponent.literal then
		return '{{Literal|}}'
	end

	return ''
end

return WikiCopyPaste
