---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--- copied from LAB until we have a proper match2 setup for this wiki

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class IdentityvMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBool(args.score), bestof == 0)
	local opponent = WikiCopyPaste.getOpponent(mode, showScore)

	local lines = Array.extendWith({},
		'{{Match|finished=',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and (INDENT .. '|winner=') or nil,
		INDENT .. '|date=',
		Logic.readBool(args.streams) and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. opponent
		end),
		bestof ~= 0 and Array.map(Array.range(1, bestof), WikiCopyPaste._getMapCode) or nil,
		INDENT .. '}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex)
	---@param opponentIndex integer
	---@param charType string
	---@param limit integer
	---@return string
	local charsCode = function(opponentIndex, charType, limit)
		local params = Array.map(Array.range(1, limit), function(runIndex)
				return '|t' .. opponentIndex .. charType .. runIndex .. '='
		end)
		return table.concat(params)
	end

	local lines = {
		INDENT .. '|map' .. mapIndex .. '={{Map|map=|finished=|t1firstside=',
		INDENT .. INDENT .. '|t1hunter=|t1survivor=',
		INDENT .. INDENT .. charsCode(1, 'pick', 5),
		INDENT .. INDENT .. charsCode(1, 'ban', 6),
		INDENT .. INDENT .. '|t2hunter=|t2survivor=',
		INDENT .. INDENT .. charsCode(2, 'pick', 5),
		INDENT .. INDENT .. charsCode(2, 'ban', 6),
		INDENT .. INDENT .. '}}',
	}

	return table.concat(lines, '\n')
end

return WikiCopyPaste
