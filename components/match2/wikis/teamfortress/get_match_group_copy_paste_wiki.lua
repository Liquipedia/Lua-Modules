---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class TeamFortressMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.readBool(args.score)
	local stats = Logic.readBool(args.stats)
	local streams = Logic.readBool(args.streams)

	local lines = Array.flatten({
		'{{Match',
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|date= |finished=',
	})

	if streams then
		table.insert(lines, INDENT .. '|twitch=|vod=')
	end

	if stats then
		table.insert(lines, INDENT .. '|etf2l=|rgl=|ozf=|tftv=')
	end

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.appendWith(lines, INDENT .. '|map' .. mapIndex ..
			'={{Map|map=|score1=|score2=|finished= |logstf= |logstfgold=}}')
	end)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

return WikiCopyPaste
