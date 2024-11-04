---
-- @Liquipedia
-- wiki=zula
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
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

	-- Map Info
	local mapInfo = mw.html.create('div')
	mapInfo	:addClass('brkts-popup-spaced')
			:wikitext('[[' .. game.map .. ']]')
			:css('text-align', 'center')
			:css('padding','5px 2px')
			:css('flex-grow','1')

	if game.resultType == 'np' then
		mapInfo:addClass('brkts-popup-spaced-map-skip')
	elseif game.resultType == 'draw' then
		mapInfo:wikitext('<i>(Draw)</i>')
	end

	-- Build the HTML
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))

	row:addElement(mapInfo)

	row:addElement(DisplayHelper.MapScore(game.scores[2], 2, game.resultType, game.walkover, game.winner))
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game'):css('font-size', '85%'):css('overflow', 'hidden')

	return row:create()
end

return CustomMatchSummary
