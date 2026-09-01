---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class DeadlockMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local showScore = Logic.nilOr(Logic.readBoolOrNil, bestof == 0)
	local bans = args.bans

	local lines = Array.extend(
		'{{Match|bestof=' .. (bestof ~= 0 and bestof or ''),
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		INDENT .. '|date=',
		INDENT .. '|twitch=|youtube=|vod=',
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, bans)
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param bans integer
---@return string
function WikiCopyPaste._getMapCode(mapIndex, bans)
	banBool = true
	ban1Text = ""
	ban2Text = ""
	if bans == 0 then
		banBool = false
	else
		for ban = 1, bans do
			ban1Text = ban1Text .. "|t1b" .. ban .. "="
			ban2Text = ban2Text .. "|t2b" .. ban .. "="
		end
	end
	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|team1side=',
		INDENT .. INDENT .. '|t1h1=|t1h2=|t1h3=|t1h4=|t1h5=|t1h6=',
		banBool and (INDENT .. INDENT .. ban1Text) or nil,
		INDENT .. INDENT .. '|team2side=',
		INDENT .. INDENT .. '|t2h1=|t2h2=|t2h3=|t2h4=|t2h5=|t2h6=',
		banBool and (INDENT .. INDENT .. ban2Text) or nil,
		INDENT .. INDENT .. '|length=|winner=|matchid=|vod=',
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste

