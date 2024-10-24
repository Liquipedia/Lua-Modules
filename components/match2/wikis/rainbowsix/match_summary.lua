---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local POSITION_LEFT = 1
local POSITION_RIGHT = 2

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local ROUND_ICONS = {
	atk = '[[File:R6S Para Bellum atk logo.png|14px|link=]]',
	def = '[[File:R6S Para Bellum def logo.png|14px|link=]]',
	otatk = '[[File:R6S Para Bellum atk logo ot rounds.png|11px|link=]]',
	otdef = '[[File:R6S Para Bellum def logo ot rounds.png|11px|link=]]',
}

local TBD = Abbreviation.make('TBD', 'To Be Determined')

-- Operator Bans Class
---@class R6OperatorBan
---@operator call: R6OperatorBan
---@field root Html
---@field text string
local OperatorBans = Class.new(
	function(self)
		self.root = mw.html.create('table')
		self.text = ''
	end
)

---@return self
function OperatorBans:setLeft()
	self.root
		:addClass('brkts-popup-body-operator-bans')
		:css('float', 'left')

	return self
end

---@return self
function OperatorBans:setRight()
	self.root
		:addClass('brkts-popup-body-operator-bans')
		:css('float', 'right')

	return self
end

---@param operator string?
---@return self
function OperatorBans:add(operator)
	if Logic.isEmpty(operator) then
		return self
	end
	self.root
		:tag('tr')
			:tag('td')
				:css('padding', '0')
				:tag('div')
					:wikitext(CharacterIcon.Icon{
						character = operator,
						size = '50x50px'
					})
	return self
end

---@return Html
function OperatorBans:create()
	self.root:wikitext(self.text)
	return self.root
end

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
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		body:addRow(CustomMatchSummary._createMap(game))
	end

	-- Add Match MVP(s)
	if Table.isNotEmpty(match.extradata.mvp) then
		body.root:node(MatchSummaryWidgets.Mvp{
			players = match.extradata.mvp.players,
			points = match.extradata.mvp.points,
		})
	end

	-- casters
	body.root:node(MatchSummaryWidgets.Casters{casters = match.extradata.casters})

	-- Add the Map Vetoes
	body:addRow(MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto, {game = 'siege'}))

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
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
	local operatorBans = {team1 = extradata.t1bans or {}, team2 = extradata.t2bans or {}}
	local team1OperatorBans = OperatorBans():setLeft()
	local team2OperatorBans = OperatorBans():setRight()

	for _, operator in ipairs(operatorBans.team1) do
		team1OperatorBans:add(operator)
	end
	for _, operator in ipairs(operatorBans.team2) do
		team2OperatorBans:add(operator)
	end

	-- Add everything to view
	if team1OperatorBans ~= nil then
		row:addElement(team1OperatorBans:create())
	end
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1, POSITION_LEFT))
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
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2, POSITION_RIGHT))
	if team2OperatorBans ~= nil then
		row:addElement(team2OperatorBans:create())
	end

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
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

	return row
end

---@param side string
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

---@param isWinner boolean?
---@param position integer
---@return Html
function CustomMatchSummary._createCheckMark(isWinner, position)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if isWinner then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	if position == POSITION_LEFT then
		container:css('margin-left', '3%')
	elseif position == POSITION_RIGHT then
		container:css('margin-right', '3%')
	end

	return container
end

return CustomMatchSummary
