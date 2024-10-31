---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ValorantScore
---@operator call: ValorantScore
---@field root Html
---@field table Html
---@field top Html
---@field bottom Html
local Score = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.table = self.root:tag('table'):css('line-height', '20px'):css('text-align', 'center')
		self.top = mw.html.create('tr')
		self.bottom = mw.html.create('tr')
	end
)

---@return self
function Score:setLeft()
	self.root	:css('float', 'left')
				:css('margin-left', '4px')

	return self
end

---@return self
function Score:setRight()
	self.root	:css('float', 'right')
				:css('margin-right', '4px')

	return self
end

---@param score string?
---@return self
function Score:setMapScore(score)
	local mapScore = mw.html.create('td')
			:attr('rowspan', '2')
			:css('font-size', '16px')
			:css('width', '24px')
			:wikitext(score)
	self.top:node(mapScore)

	return self
end

---@param side string
---@param score number
---@return self
function Score:addTopRoundScore(side, score)
	local roundScore = mw.html.create('td')
	roundScore	:addClass('bracket-popup-body-match-sidewins')
				:addClass('brkts-valorant-score-color-' .. side)
				:css('width', '12px')
				:wikitext(score)
	self.top:node(roundScore)
	return self
end

---@param side string
---@param score number
---@return self
function Score:addBottomRoundScore(side, score)
	local roundScore = mw.html.create('td')
	roundScore	:addClass('bracket-popup-body-match-sidewins')
				:addClass('brkts-valorant-score-color-' .. side)
				:css('width', '12px')
				:wikitext(score)
	self.bottom:node(roundScore)
	return self
end

---@return Html
function Score:create()
	self.table:node(self.top):node(self.bottom)
	return self.root
end

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local mapVeto = MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMap),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters},
		mapVeto and mapVeto:create() or nil
	)}
end

---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end

	local row = MatchSummary.Row()

	local team1Agents = Array.map((game.opponents[1] or {}).players or {}, Operator.property('agent'))
	local team2Agents = Array.map((game.opponents[2] or {}).players or {}, Operator.property('agent'))

	local extradata = game.extradata or {}
	local score1 = Score():setLeft()
	local score2 = Score():setRight()

	score1:setMapScore(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))

	if Logic.isNotEmpty(extradata) then
		-- Detailed scores
		local team1Halfs = extradata.t1halfs or {}
		local team2Halfs = extradata.t2halfs or {}
		local firstSide = string.lower(extradata.t1firstside or '')
		local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)

		score1:addTopRoundScore(firstSide, team1Halfs[firstSide])
		score1:addBottomRoundScore(oppositeSide, team1Halfs[oppositeSide])

		score1:addTopRoundScore(firstSide, team1Halfs['ot' .. firstSide])
		score1:addBottomRoundScore(oppositeSide, team1Halfs['ot' .. oppositeSide])

		score2:addTopRoundScore(oppositeSide, team2Halfs['ot' .. oppositeSide])
		score2:addBottomRoundScore(firstSide, team2Halfs['ot' .. firstSide])

		score2:addTopRoundScore(oppositeSide, team2Halfs[oppositeSide])
		score2:addBottomRoundScore(firstSide, team2Halfs[firstSide])
	end

	score2:setMapScore(DisplayHelper.MapScore(game.scores[2], 2, game.resultType, game.walkover, game.winner))

	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(MatchSummaryWidgets.Characters{characters = team1Agents, flipped = false})
	row:addElement(score1:create())

	local centerNode = mw.html.create('div')
	centerNode	:addClass('brkts-popup-spaced')
				:wikitext('[[' .. game.map .. ']]')
				:css('width', '100px')
				:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	row:addElement(centerNode)

	row:addElement(score2:create())
	row:addElement(MatchSummaryWidgets.Characters{characters = team2Agents, flipped = true})
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game')
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
