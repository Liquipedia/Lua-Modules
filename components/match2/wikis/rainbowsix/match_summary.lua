---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ROUND_ICONS = {
	atk = '[[File:R6S Para Bellum atk logo.png|14px|link=]]',
	def = '[[File:R6S Para Bellum def logo.png|14px|link=]]',
	otatk = '[[File:R6S Para Bellum atk logo ot rounds.png|11px|link=]]',
	otdef = '[[File:R6S Para Bellum def logo ot rounds.png|11px|link=]]',
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
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMap),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = 'siege'}))
	)}
end

---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	local function operatorDisplay(operators)
		return HtmlWidgets.Div{
			classes = {'brkts-popup-body-operator-bans'},
			children = Array.map(operators, function(operator)
				return MatchSummaryWidgets.Character{
					character = operator,
					size = '50x50px'
				}
			end)
		}
	end
	local function makePartialScores(halves, firstSide)
		local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)
		return {
			{style = 'brkts-popup-body-match-sidewins', score = halves[firstSide], icon = ROUND_ICONS[firstSide]},
			{style = 'brkts-popup-body-match-sidewins', score = halves[oppositeSide], icon = ROUND_ICONS[oppositeSide]},
			{
				style = 'brkts-popup-body-match-sidewins-overtime',
				score = halves['ot' .. firstSide],
				icon = ROUND_ICONS['ot' .. firstSide]
			},
			{
				style = 'brkts-popup-body-match-sidewins-overtime',
				score = halves['ot' .. oppositeSide],
				icon = ROUND_ICONS['ot' .. oppositeSide]
			},
		}
	end

	-- Detailed scores
	local firstSides = extradata.t1firstside or {}
	local firstSide = (firstSides.rt or ''):lower()
	local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)

	-- Operator bans

	row:addElement(operatorDisplay(extradata.t1bans or {}))
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(MatchSummaryWidgets.DetailedScore{
		score = scoreDisplay(1),
		partialScores = makePartialScores(
			extradata.t1halfs or {},
			firstSide
		)
	})

	local centerNode = mw.html.create('div')
	centerNode	:addClass('brkts-popup-spaced')
				:wikitext('[[' .. game.map .. ']]')
				:css('text-align', 'center')
				:css('padding','5px 2px')
				:css('flex-grow','1')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	row:addElement(centerNode)

	row:addElement(MatchSummaryWidgets.DetailedScore{
		score = scoreDisplay(2),
		partialScores = makePartialScores(
			extradata.t2halfs or {},
			oppositeSide
		)
	})
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})
	row:addElement(operatorDisplay(extradata.t2bans or {}))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game'):css('font-size', '85%')

	-- Winner/Loser backgrounds
	if game.winner == 1 then
		row:addClass('brkts-popup-body-gradient-left')
	elseif game.winner == 2 then
		row:addClass('brkts-popup-body-gradient-right')
	elseif game.resultType == 'draw' then
		row:addClass('brkts-popup-body-gradient-draw')
	else
		row:addClass('brkts-popup-body-gradient-default')
	end

	return row:create()
end

---@param side string
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

return CustomMatchSummary
