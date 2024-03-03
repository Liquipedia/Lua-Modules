---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseCopyPaste = Table.copy(require('Module:GetMatchGroupCopyPaste/wiki/Base'))
local Opponent = Lua.import('Module:Opponent')

---@class WorldofTanksMatch2CopyPaste: Match2CopyPasteBase
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
	local streams = Logic.readBool(args.streams)
	local showScore = Logic.readBool(args.score)

	local lines = {
		'{{Match',
		INDENT .. table.concat(Array.map(Array.range(1, opponents), function(opponentIndex)
			return '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode, showScore)
		end)),
		INDENT .. '|date= |finished=',
	}

	if streams then
		table.insert(lines, INDENT .. '|twitch=|vod=')
	end

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.appendWith(lines,
			INDENT .. '|map' .. mapIndex .. '={{Map|map=|score1=|score2=|finished=')
		lines[#lines] = lines[#lines] .. '}}'
	end)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

---subfunction used to generate the code for the Opponent template, depending on the type of opponent
---@param mode string
---@param showScore boolean
---@return string
function WikiCopyPaste._getOpponent(mode, showScore)
	local score = showScore and '|score=' or ''
	if mode == Opponent.solo then
		return '{{PlayerOpponent||flag=' .. score .. '}}'
	elseif mode == Opponent.team then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == Opponent.literal then
		return '{{LiteralOpponent|}}'
	end

	return ''
end

return WikiCopyPaste
