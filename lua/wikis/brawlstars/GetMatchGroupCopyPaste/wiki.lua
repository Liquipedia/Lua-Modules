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
local String = require('Module:StringUtils')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local CONVERT_PICK_BAN_ENTRY = {
	none = {},
	pick = {'pick'},
	ban = {'ban'},
	player = {'player'},
	['pick + ban'] = {'pick', 'ban'},
	['pick + player'] = {'player', 'pick'},
	['ban + player'] = {'player', 'ban'},
	all = {'player', 'pick', 'ban'},
}
local PARAM_TO_SHORT = {
	pick = 'c',
	ban = 'b',
	player = 'p',
}
local LIMIT_OF_PARAM = {
	pick = 3,
	ban = 3,
	player = 3,
}

---@class BrawlstarsMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param matchIndex integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, matchIndex, opponents, args)
	local showScore = Logic.readBool(args.score)

	local lines = Array.extend(
		'{{Match',
		matchIndex == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end)
	)

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.extendWith(lines, WikiCopyPaste._getMapCode(args, matchIndex, opponents, mapIndex))
	end)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
---@param args table
---@param matchIndex integer
---@param numberOfOpponents integer
---@param mapIndex integer
---@return string[]
function WikiCopyPaste._getMapCode(args, matchIndex, numberOfOpponents, mapIndex)
	local lines = {
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|map=|maptype=|firstpick=',
		INDENT .. INDENT .. '|score1=|score2=',
	}

	Array.forEach(CONVERT_PICK_BAN_ENTRY[args.pickBan or ''] or {}, function(item)
		Array.extendWith(lines, WikiCopyPaste._pickBanParams(item, numberOfOpponents))
	end)

	--first map has additional mapBestof if it is the first match
	if matchIndex == 1 and mapIndex == 1 and String.isNotEmpty(args.mapBestof) then
		Array.appendWith(lines, INDENT .. INDENT .. '|bestof=' .. args.mapBestof)
	end

	return Array.append(lines, INDENT .. '}}')
end

---@param key string
---@param numberOfOpponents integer
---@return string[]
function WikiCopyPaste._pickBanParams(key, numberOfOpponents)
	local shortKey = PARAM_TO_SHORT[key]
	local limit = LIMIT_OF_PARAM[key]

	return Array.map(Array.range(1, numberOfOpponents), function(opponentIndex)
		return INDENT .. INDENT .. table.concat(Array.map(Array.range(1, limit), function(keyIndex)
			return '|t' .. opponentIndex .. shortKey .. keyIndex .. '='
		end))
	end)
end

return WikiCopyPaste
