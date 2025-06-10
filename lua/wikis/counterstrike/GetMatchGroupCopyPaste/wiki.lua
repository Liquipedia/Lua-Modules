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
local Opponent = Lua.import('Module:Opponent')

---@class CounterstrikeMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

local GSL_STYLE_WITH_EXTRA_MATCH_INDICATOR = 'gf'
local GSL_WINNERS = 'winners'
local GSL_LOSERS = 'losers'

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
	local mapDetails = Logic.readBool(args.detailedMap)
	local mapDetailsOT = Logic.readBool(args.detailedMapOT)
	local hltv = Logic.readBool(args.hltv)
	local mapStats = args.mapStats and Array.unique(mw.text.split(args.mapStats, ', ')) or {}
	local matchMatchpages = args.matchMatchpages and Array.unique(mw.text.split(args.matchMatchpages, ', ')) or {}

	if hltv then
		table.insert(mapStats, 'Stats')
		table.insert(matchMatchpages, 1, 'HLTV')
	end

	local lines = {
		'{{Match',
		INDENT .. table.concat(Array.map(Array.range(1, opponents), function(opponentIndex)
			return '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste._getOpponent(mode, showScore)
		end)),
		INDENT .. '|date= |finished=',
	}

	if streams then
		table.insert(mapStats, 'vod')
		table.insert(lines, INDENT .. '|twitch=')
	end

	---@param list string[]
	---@param indents integer
	---@return string?
	local buildListLine = function(list, indents)
		if #list == 0 then return nil end

		return string.rep(INDENT, indents) .. table.concat(Array.map(list, function(elemenmt)
			return '|' .. elemenmt:lower() .. '='
		end))
	end

	local mapStatsLine = buildListLine(mapStats, 2)

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.appendWith(lines,
			INDENT .. '|map' .. mapIndex .. '={{Map|map=' .. (mapDetails and '' or '|score1=|score2=') .. '|finished=',
			mapDetails and (INDENT .. INDENT .. '|t1firstside=|t1t=|t1ct=|t2t=|t2ct=') or nil,
			mapDetails and mapDetailsOT and (INDENT .. INDENT .. '|o1t1firstside=|o1t1t=|o1t1ct=|o1t2t=|o1t2ct=') or nil,
			mapStatsLine
		)
		lines[#lines] = lines[#lines] .. '}}'
	end)

	Array.appendWith(lines,
		buildListLine(matchMatchpages, 1),
		INDENT .. '}}'
	)

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

---@param template string
---@param id string
---@param modus string
---@param args table
---@return string
---@return table
function WikiCopyPaste.getStart(template, id, modus, args)
	args.namedMatchParams = false
	args.headersUpTop = Logic.readBool(Logic.emptyOr(args.headersUpTop, true))

	local start = '{{' .. WikiCopyPaste.getMatchGroupTypeCopyPaste(modus, template) .. '|id=' .. id

	local gslStyle = args.gsl
	if modus ~= 'matchlist' or not gslStyle then
		return start, args
	end

	args.customHeader = false

	if not String.startsWith(gslStyle:lower(), GSL_STYLE_WITH_EXTRA_MATCH_INDICATOR) then
		args.matches = 5
		return start .. '|gsl=' .. gslStyle, args
	end

	args.matches = 6
	if String.endsWith(gslStyle:lower(), GSL_WINNERS) then
		start = start .. '|gsl=' .. 'winnersfirst'
	elseif String.endsWith(gslStyle:lower(), GSL_LOSERS) then
		start = start .. '|gsl=' .. 'losersfirst'
	end
	start = start .. '\n|M6header=Grand Final'

	return start, args
end

return WikiCopyPaste
