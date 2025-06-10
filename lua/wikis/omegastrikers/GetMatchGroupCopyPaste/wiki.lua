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
	ban = 1,
	player = 3,
}

---@class OmegastrikersMatch2CopyPaste: Match2CopyPasteBase
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

	local lines = Array.extend(
		'{{Match',
		bestof ~= 0 and (INDENT .. '|bestof=' .. bestof) or nil,
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|twitch='
		} or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Array.map(Array.range(1, bestof), function (mapIndex)
			return INDENT .. '|map' .. mapIndex .. '=' .. WikiCopyPaste._getMap(opponents, args.pickBan, args.mapBestof)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@private
---@param opponents integer
---@param pickBan string?
---@param mapBestOf integer?
---@return string
function WikiCopyPaste._getMap(opponents, pickBan, mapBestOf)
	local map = Array.extend(
		'{{Map',
		INDENT .. INDENT .. '|map=',
		INDENT .. INDENT .. '|score1=|score2=',
		Array.flatMap(CONVERT_PICK_BAN_ENTRY[pickBan or ''] or {}, function (element)
			return WikiCopyPaste._pickBanParams(element, opponents)
		end),
		mapBestOf and (INDENT .. INDENT .. '|bestof=' .. mapBestOf) or nil,
		INDENT .. '}}'
	)

	return table.concat(map, '\n')
end

---@private
---@param key string
---@param numberOfOpponents integer
---@return string[]
function WikiCopyPaste._pickBanParams(key, numberOfOpponents)
	local shortKey = PARAM_TO_SHORT[key]
	local limit = LIMIT_OF_PARAM[key]
	local display = Array.map(Array.range(1, numberOfOpponents), function (opponentIndex)
		return INDENT .. INDENT .. table.concat(Array.map(Array.range(1, limit), function (keyIndex)
			return '|t' .. opponentIndex .. shortKey .. keyIndex .. '='
		end))
	end)

	return display
end

return WikiCopyPaste
