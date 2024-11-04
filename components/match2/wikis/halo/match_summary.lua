---
-- @Liquipedia
-- wiki=halo
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMapRow),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters}
	)}
end

---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createMapRow(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummaryWidgets.Break{})
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local displayScore = function(opponentIndex)
		local score = DisplayHelper.MapScore(
			game.scores[opponentIndex],
			opponentIndex,
			game.resultType,
			game.walkover,
			game.winner
		)
		local points = game.extradata['points' .. opponentIndex]
		if not points then
			return score
		end
		local flipped = opponentIndex == 2
		if flipped then
			return '(' .. points .. ') ' .. score
		end
		return score .. ' (' .. points .. ')'
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
		:node(displayScore(1))

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(displayScore(2))
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row:create()
end

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'
	if String.isNotEmpty(game.mode) then
		mapDisplay = MapModes.get{mode = game.mode} .. mapDisplay
	end
	return mapDisplay
end

return CustomMatchSummary
