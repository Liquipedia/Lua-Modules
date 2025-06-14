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

---@class HonorofkingsMatch2CopyPaste: Match2CopyPasteBase
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
	local showScore = Logic.nilOr(Logic.readBoolOrNil(args.score), bestof == 0)
	local numberOfBans = tonumber(args.bans) or 0

	local lines = Array.extend(
		'{{Match',
		index == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.needsWinner) and INDENT .. '|winner=' or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		Logic.readBool(args.hasDate) and {
			INDENT .. '|date=',
			INDENT .. '|twitch= |youtube= |bilibili= |douyu= |huya=',
			INDENT .. '|mvp=',
			args.vod == 'series' and (INDENT .. '|vod=') or nil,
		} or nil,
		Array.map(Array.range(1, bestof), function(mapIndex)
			return WikiCopyPaste._getMapCode(mapIndex, numberOfBans, args.vod == 'maps')
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param mapIndex integer
---@param numberOfBans integer
---@param showVod boolean
---@return string
function WikiCopyPaste._getMapCode(mapIndex, numberOfBans, showVod)
	numberOfBans = numberOfBans or 0
	local getBans = function(opponentIndex)
		if numberOfBans == 0 then
			return nil
		end
		return INDENT .. INDENT .. table.concat(Array.map(Array.range(1, numberOfBans), function(banIndex)
				return '|t' .. opponentIndex .. 'b' .. banIndex .. '='
			end), ' ')
	end

	return table.concat(Array.extend(
		INDENT .. '|map' .. mapIndex .. '={{Map' ..  (showVod and '|vod=' or ''),
		INDENT .. INDENT .. '|team1side= |team2side= |length= |winner=',
		INDENT .. INDENT .. '<!-- Hero picks -->',
		INDENT .. INDENT .. '|t1h1= |t1h2= |t1h3= |t1h4= |t1h5=',
		INDENT .. INDENT .. '|t2h1= |t2h2= |t2h3= |t2h4= |t2h5=',
		numberOfBans > 0 and (INDENT .. INDENT .. '<!-- Hero bans-->') or nil,
		getBans(1),
		getBans(2),
		INDENT .. '}}'
	), '\n')
end

return WikiCopyPaste
