---
-- @Liquipedia
-- wiki=geoguessr
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local Icons = {
	CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'},
	EMPTY = '[[File:NoCheck.png|link=]]',
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if not DateExt.isDefaultTimestamp(match.timestamp) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default timestamp, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	Array.forEach(match.games, function(game)
		body:addRow(CustomMatchSummary._createMapRow(game))
	end)

	return body
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex]
	local scoreDisplay = DisplayHelper.MapScore(score, opponentIndex, game.resultType, game.walkover, game.winner)
	return mw.html.create('div'):wikitext(scoreDisplay)
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext(Page.makeInternalLink(game.map))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, Icons.CHECK))
		:node(CustomMatchSummary._gameScore(game, 1))
		:css('width', '20%')

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, Icons.CHECK))
		:css('width', '20%')

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

	return row
end

---@param showIcon boolean?
---@param icon string?
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, icon)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '27px')
		:node(showIcon and icon or Icons.EMPTY)
end

return CustomMatchSummary
