---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local POSITION_LEFT = 1
local POSITION_RIGHT = 2

local ROUND_ICONS = {
	atk = '[[File:R6S Para Bellum atk logo.png|14px|link=]]',
	def = '[[File:R6S Para Bellum def logo.png|14px|link=]]',
	otatk = '[[File:R6S Para Bellum atk logo ot rounds.png|11px|link=]]',
	otdef = '[[File:R6S Para Bellum def logo ot rounds.png|11px|link=]]',
}

-- Score Class, both for the "big" score, and the halfs scores
---@class R6Score
---@operator call: R6Score
---@field root Html
---@field table Html
---@field top Html
---@field bottom Html
local Score = Class.new(
	function(self)
		self.root = mw.html.create('div'):css('width','70px'):css('text-align', 'center')
		self.table = self.root:tag('table'):css('line-height', '29px')
		self.top = mw.html.create('tr')
		self.bottom = mw.html.create('tr')
	end
)

---@return self
function Score:setLeft()
	self.table
		:css('float', 'left')

	return self
end

---@return self
function Score:setRight()
	self.table
		:css('float', 'right')

	return self
end

---@param score string|number|nil
---@return self
function Score:setMapScore(score)
	local mapScore = mw.html.create('td')
	mapScore
		:attr('rowspan', '2')
		:css('font-size', '16px')
		:css('width', '25px')
		:wikitext(score or '')

	self.top:node(mapScore)

	return self
end

---@param side string
---@param score number
---@param position integer
---@return self
function Score:setFirstRoundScore(side, score, position)
	local icon = ROUND_ICONS[side]
	local leftElement, rightElement
	if position == POSITION_RIGHT then -- For right side, swap order of score and icon
		leftElement, rightElement = score, icon
	else
		leftElement, rightElement = icon, score
	end

	local roundScore = mw.html.create('td')
	roundScore	:addClass('brkts-popup-body-match-sidewins')
				:wikitext(leftElement)
				:wikitext(rightElement)

	self.top:node(roundScore)
	return self
end

---@param side string
---@param score number
---@param position integer
---@return self
function Score:setSecondRoundScore(side, score, position)
	local icon = ROUND_ICONS[side]
	local leftElement, rightElement
	if position == POSITION_RIGHT then -- For right side, swap order of score and icon
		leftElement, rightElement = score, icon
	else
		leftElement, rightElement = icon, score
	end

	local roundScore = mw.html.create('td')
	roundScore	:addClass('brkts-popup-body-match-sidewins')
				:wikitext(leftElement)
				:wikitext(rightElement)

	self.bottom:node(roundScore)
	return self
end

---@param side string
---@param score number
---@param position integer
---@return self
function Score:setFirstOvertimeRoundScore(side, score, position)
	local icon = ROUND_ICONS['ot' .. side]
	local leftElement, rightElement
	if position == POSITION_RIGHT then -- For right side, swap order of score and icon
		leftElement, rightElement = score, icon
	else
		leftElement, rightElement = icon, score
	end

	local roundScore = mw.html.create('td')
	roundScore	:addClass('brkts-popup-body-match-sidewins-overtime')
				:wikitext(leftElement)
				:wikitext(rightElement)

	self.top:node(roundScore)
	return self
end

---@param side string
---@param score number
---@param position integer
---@return self
function Score:setSecondOvertimeRoundScore(side, score, position)
	local icon = ROUND_ICONS['ot'..side]
	local leftElement, rightElement
	if position == POSITION_RIGHT then -- For right side, swap order of score and icon
		leftElement, rightElement = score, icon
	else
		leftElement, rightElement = icon, score
	end

	local roundScore = mw.html.create('td')
	roundScore	:addClass('brkts-popup-body-match-sidewins-overtime')
				:wikitext(leftElement)
				:wikitext(rightElement)

	self.bottom:node(roundScore)
	return self
end

---@return self
function Score:addEmptyOvertime()
	local roundScore = mw.html.create('td'):css('width','20px')
	self.top:node(roundScore)
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
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local mapVeto = MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto, {game = 'siege'})

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

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score():setRight()

	-- Score Team 1
	team1Score:setMapScore(scoreDisplay(1))

	-- Detailed scores
	local team1Halfs = extradata.t1halfs or {}
	local team2Halfs = extradata.t2halfs or {}
	local firstSides = extradata.t1firstside or {}

	local firstSide = (firstSides.rt or ''):lower()
	local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)

	if not Logic.isEmpty(firstSide) then
		-- Regular Time for Team 1
		team1Score:setFirstRoundScore(firstSide, team1Halfs[firstSide], POSITION_LEFT)
		team1Score:setSecondRoundScore(oppositeSide, team1Halfs[oppositeSide], POSITION_LEFT)

		-- Overtime for both, if applicable
		local firstSideOvertime = firstSides.ot
		local oppositeSideOvertime = CustomMatchSummary._getOppositeSide(firstSideOvertime)

		if not Logic.isEmpty(firstSideOvertime) then
			team1Score:setFirstOvertimeRoundScore(firstSideOvertime, team1Halfs['ot' .. firstSideOvertime], POSITION_LEFT)
			team1Score:setSecondOvertimeRoundScore(oppositeSideOvertime, team1Halfs['ot' .. oppositeSideOvertime], POSITION_LEFT)

			team2Score:setFirstOvertimeRoundScore(oppositeSideOvertime, team2Halfs['ot' .. oppositeSideOvertime], POSITION_RIGHT)
			team2Score:setSecondOvertimeRoundScore(firstSideOvertime, team2Halfs['ot' .. firstSideOvertime], POSITION_RIGHT)
		else
			team1Score:addEmptyOvertime()
			team2Score:addEmptyOvertime()
		end

		-- Regular Time for Team 2
		team2Score:setFirstRoundScore(oppositeSide, team2Halfs[oppositeSide], POSITION_RIGHT)
		team2Score:setSecondRoundScore(firstSide, team2Halfs[firstSide], POSITION_RIGHT)
	end

	-- Score Team 2
	team2Score:setMapScore(scoreDisplay(2))

	-- Operator bans

	row:addElement(operatorDisplay(extradata.t1bans or {}))
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(team1Score:create())

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

	row:addElement(team2Score:create())
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
