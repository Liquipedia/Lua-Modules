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
			return '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end)),
		INDENT .. '|date= |finished=',
	}

	if streams then
		table.insert(lines, INDENT .. '|twitch=|vod=')
	end

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.appendWith(lines, INDENT .. '|map' .. mapIndex ..
			'={{Map|map=|score1=|score2=|finished=}}')
	end)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

return WikiCopyPaste
