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
local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local MODE_CONVERSION = {
	['1v1'] = {Opponent.solo},
	['2v2'] = {Opponent.duo},
	['3v3'] = {Opponent.trio},
	['4v4'] = {Opponent.quad},
	['literal'] = {Opponent.literal},
	['team - 1v1'] = {Opponent.solo, isTeamMatch = true},
	['team - 2v2'] = {Opponent.duo, isTeamMatch = true},
	['team - 3v3'] = {Opponent.trio, isTeamMatch = true},
	['team - 4v4'] = {Opponent.quad, isTeamMatch = true},
}
MODE_CONVERSION.default = MODE_CONVERSION['1v1']

---@class WarcraftMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

---Returns the cleaned opponent type
---@param mode string
---@return {[1]: OpponentType, isTeamMatch: boolean?}
---@diagnostic disable-next-line: inject-field
function WikiCopyPaste.getMode(mode)
	return MODE_CONVERSION[string.lower(mode or '')] or MODE_CONVERSION.default
end

---Returns the Code for a Match, depending on the input
---@param bestof number
---@param mode {[1]: OpponentType, isTeamMatch: boolean?}
---@param index number
---@param opponents number
---@param args table
---@return string
---@diagnostic disable-next-line: inject-field
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	if bestof == 0 then
		args.score = true
	end
	local score = Logic.readBool(args.score) and '|score=' or ''

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {}
	)

	for opponentIndex = 1, opponents do
		table.insert(lines, INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode, score))
	end

	if bestof > 0 then
		local submatchBo = tonumber(args.submatch)
		Array.forEach(Array.range(1, bestof), function(gameIndex)
			local subgroup = ''
			if submatchBo then
				subgroup = '|subgroup=' .. (math.floor((gameIndex - 1) / submatchBo) + 1)
			elseif mode.isTeamMatch and Logic.readBool(args.submatch) then
				subgroup = '|subgroup='
			end
			table.insert(lines, INDENT .. '|map' .. gameIndex .. '={{Map|map=|winner=' .. subgroup
				.. WikiCopyPaste._mapDetails(opponents, mode))
		end)
	end

	local vetoes = tonumber(args.vetoes) or 0
	if vetoes > 0 then
		Array.forEach(Array.range(1, vetoes), function(vetoIndex)
			local prefix = '|veto' .. vetoIndex
			table.insert(lines, INDENT .. prefix .. '=' .. prefix .. 'by=')
		end)
	end

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

---@param opponents number
---@param mode {[1]: OpponentType, isTeamMatch: boolean?}
---@return string
---@diagnostic disable-next-line: inject-field
function WikiCopyPaste._mapDetails(opponents, mode)
	if mode[1] == Opponent.literal then return '}}' end
	local lines = {''}

	Array.forEach(Array.range(1, opponents), function(opponentIndex)
		Array.forEach(Array.range(1, Opponent.partySize(mode[1]) --[[@as integer]]), function(playerIndex)
			local prefix = '|t' .. opponentIndex .. 'p' .. playerIndex
			local player = mode.isTeamMatch and (prefix .. '=') or ''
			table.insert(lines, INDENT .. INDENT .. player .. prefix .. 'heroes=')
		end)
	end)

	table.insert(lines, INDENT .. '}}')

	return table.concat(lines, '\n')
end

---Subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode {[1]: OpponentType, isTeamMatch: boolean?}
---@param score string
---@return string
---@diagnostic disable-next-line: inject-field
function WikiCopyPaste._getOpponent(mode, score)
	if mode.isTeamMatch then
		return '{{TeamOpponent|template=' .. score .. '}}'
	elseif mode[1] == Opponent.literal then
		return '{{LiteralOpponent|template=' .. score .. '}}'
	end

	local players = ''
	Array.forEach(Array.range(1, Opponent.partySize(mode[1]) --[[@as integer]]), function(playerIndex)
		players = players .. '|p' .. playerIndex .. '=' .. '|p' .. playerIndex .. 'race='
	end)

	return '{{' .. mw.getContentLanguage():ucfirst(mode[1]) .. 'Opponent' .. players .. score .. '}}'
end

return WikiCopyPaste
