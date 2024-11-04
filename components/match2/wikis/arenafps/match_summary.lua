---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end
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
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
		:node(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))
		:css('width', '20%')

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(DisplayHelper.MapScore(game.scores[2], 2, game.resultType, game.walkover, game.winner))
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})
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

	return row:create()
end

return CustomMatchSummary
