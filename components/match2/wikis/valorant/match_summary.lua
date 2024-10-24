---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

---@class ValorantAgents
---@operator call: ValorantAgents
---@field root Html
---@field text string
local Agents = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('hide-mobile')
		self.text = ''
	end
)

---@return self
function Agents:setLeft()
	self.root	:css('float', 'left')
				:css('margin-left', '10px')

	return self
end

---@return self
function Agents:setRight()
	self.root	:css('float', 'right')
				:css('margin-right', '10px')

	return self
end

---@param agent string?
---@return self
function Agents:add(agent)
	if Logic.isEmpty(agent) then
		return self
	end

	self.text = self.text .. CharacterIcon.Icon{
		character = agent,
		size = '20px'
	}
	return self
end

---@return Html
function Agents:create()
	self.root:wikitext(self.text)
	return self.root
end

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
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default date, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

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

	-- Add Map Veto
	body:addRow(MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto))

	body.root:node(MatchSummaryWidgets.Casters{casters = match.extradata.casters})

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()

	local team1Agents = Agents():setLeft()
	local team2Agents = Agents():setRight()
	for _, playerStats in ipairs((game.opponents[1] or {}).players) do
		team1Agents:add(playerStats.agent)
	end
	for _, playerStats in ipairs((game.opponents[2] or {}).players) do
		team2Agents:add(playerStats.agent)
	end

	local extradata = game.extradata or {}
	local score1 = Score():setLeft()
	local score2 = Score():setRight()

	score1:setMapScore(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))

	if not Table.isEmpty(extradata) then
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

	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	if team1Agents ~= nil then
		row:addElement(team1Agents:create())
	end
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

	if team2Agents ~= nil then
		row:addElement(team2Agents:create())
	end
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))

	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game')
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
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced')

	if isWinner then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

return CustomMatchSummary
