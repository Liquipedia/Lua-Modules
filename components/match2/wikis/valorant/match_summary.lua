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

local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local LINK_DATA = {
	vlr = {icon = 'File:VLR icon.png', text = 'Matchpage and Stats on VLR'},
}

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

---@param agent string
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
-- Map Veto Class
---@class ValorantMapVeto: MatchSummaryRowInterface
---@operator call: ValorantMapVeto
---@field root Html
---@field table Html
local MapVeto = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

---@return self
function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

---@param firstVeto number?
---@return self
function MapVeto:vetoStart(firstVeto)
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = '<b>Start Map Veto</b>'
		textCenter = ARROW_LEFT
	elseif firstVeto == 2 then
		textCenter = ARROW_RIGHT
		textRight = '<b>Start Map Veto</b>'
	else return self end
	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()
	return self
end

---@param map string?
---@return self
function MapVeto:addDecider(map)
	if Logic.isEmpty(map) then
		map = 'TBD'
	else
		map = '[[' .. map .. ']]'
	end
	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')
	self:addColumnVetoMap(row, map)
	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')

	self.table:node(row)
	return self
end

---@param vetotype string?
---@param map1 string?
---@param map2 string?
---@return self
function MapVeto:addRound(vetotype, map1, map2)
	if Logic.isEmpty(map1) then
		map1 = 'TBD'
	else
		map1 = '[[' .. map1 .. ']]'
	end
	if Logic.isEmpty(map2) then
		map2 = 'TBD'
	else
		map2 = '[[' .. map2 .. ']]'
	end
	local class
	local vetoText
	if vetotype == 'ban' then
		vetoText = 'BAN'
		class = 'brkts-popup-mapveto-ban'
	elseif vetotype == 'pick' then
		vetoText = 'PICK'
		class = 'brkts-popup-mapveto-pick'
	elseif vetotype == 'defaultban' then
		vetoText = 'DEFAULT BAN'
		class = 'brkts-popup-mapveto-defaultban'
	else
		return self
	end

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoMap(row, map1)
	self:addColumnVetoType(row, class, vetoText)
	self:addColumnVetoMap(row, map2)

	self.table:node(row)
	return self
end

---@param row Html
---@param styleClass string?
---@param vetoText string
---@return self
function MapVeto:addColumnVetoType(row, styleClass, vetoText)
	row:tag('td')
		:tag('span')
			:addClass(styleClass)
			:addClass('brkts-popup-mapveto-vetotype')
			:wikitext(vetoText)
	return self
end

---@param row Html
---@param map string
---@return self
function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map):done()
	return self
end

---@return Html
function MapVeto:create()
	return self.root
end

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer:addLinks(LINK_DATA, match.links)
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
		if game.map then
			body:addRow(CustomMatchSummary._createMap(game))
		end
	end

	-- Add Match MVP(s)
	if match.extradata.mvp then
		local mvpData = match.extradata.mvp
		if not Table.isEmpty(mvpData) and mvpData.players then
			local mvp = MatchSummary.Mvp()
			for _, player in ipairs(mvpData.players) do
				mvp:addPlayer(player)
			end
			mvp:setPoints(mvpData.points)

			body:addRow(mvp)
		end

	end

	-- Add Map Veto
	if match.extradata.mapveto then
		local vetoData = match.extradata.mapveto
		if vetoData then
			local mapVeto = MapVeto()

			for _, vetoRound in ipairs(vetoData) do
				if vetoRound.vetostart then
					mapVeto:vetoStart(tonumber(vetoRound.vetostart))
				end
				if vetoRound.type == 'decider' then
					mapVeto:addDecider(vetoRound.decider)
				else
					mapVeto:addRound(vetoRound.type, vetoRound.team1, vetoRound.team2)
				end
			end

			body:addRow(mapVeto)
		end
	end

	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createMap(game)
	local row = MatchSummary.Row()

	local team1Agents, team2Agents

	if not Table.isEmpty(game.participants) then
		team1Agents = Agents():setLeft()
		team2Agents = Agents():setRight()

		for player = 1, 5 do
			local playerStats = game.participants['1_' .. player]
			if playerStats ~= nil then
				team1Agents:add(playerStats['agent'])
			end
		end

		for player = 1, 5 do
			local playerStats = game.participants['2_' .. player]
			if playerStats ~= nil then
				team2Agents:add(playerStats['agent'])
			end
		end

	end

	local score1, score2

	local extradata = game.extradata or {}
	score1 = Score():setLeft()
	score2 = Score():setRight()

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
