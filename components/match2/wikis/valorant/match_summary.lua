---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AgentIcon = require('Module:AgentIcon')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Template = require('Module:Template')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local _ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local _ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'

local Agents = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root   :addClass('hide-mobile')
		self.text = ''
	end
)

function Agents:setLeft()
	self.root   :css('float', 'left')
				:css('margin-left', '10px')

	return self
end

function Agents:setRight()
	self.root   :css('float', 'right')
				:css('margin-right', '10px')

	return self
end

function Agents:add(frame, agent)
	if Logic.isEmpty(agent) then
		return self
	end

	self.text = self.text .. AgentIcon._getBracketIcon{agent}
	return self
end

function Agents:create()
	self.root:wikitext(self.text)
	return self.root
end

local Score = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.table = self.root:tag('table'):css('line-height', '20px')
	end
)

function Score:setLeft()
	self.root   :css('float', 'left')
				:css('margin-left', '5px')

	return self
end

function Score:setRight()
	self.root   :css('float', 'right')
				:css('margin-right', '5px')

	return self
end

function Score:setMapScore(score)
	self.top = mw.html.create('tr')
	self.bottom = mw.html.create('tr')

	local mapScore = mw.html.create('td')
	mapScore:attr('rowspan', '2')
			:css('font-size', '16px')
			:css('width', '25px')
			:wikitext(score or '')
	self.top:node(mapScore)

	return self
end

function Score:setFirstRoundScore(side, score)
	local roundScore = mw.html.create('td')
	roundScore  :addClass('bracket-popup-body-match-sidewins')
				:css('color', self:_getSideColor(side))
				:wikitext(score)
	self.top:node(roundScore)
	return self
end

function Score:setSecondRoundScore(side, score)
	local roundScore = mw.html.create('td')
	roundScore  :addClass('bracket-popup-body-match-sidewins')
				:css('color', self:_getSideColor(side))
				:wikitext(score)
	self.bottom:node(roundScore)
	return self
end

function Score:_getSideColor(side)
	if side == 'atk' then
		return '#c04845'
	elseif side == 'def' then
		return '#46b09c'
	end
end

function Score:create()
	self.table:node(self.top):node(self.bottom)
	return self.root
end

-- Map Veto Class
local MapVeto = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

function MapVeto:vetoStart(firstVeto)
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = '\'\'\'Start Map Veto\'\'\''
		textCenter = _ARROW_LEFT
	elseif firstVeto == 2 then
		textCenter = _ARROW_RIGHT
		textRight = '\'\'\'Start Map Veto\'\'\''
	else return self end
	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()
	return self
end

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

function MapVeto:addColumnVetoType(row, styleClass, vetoText)
	row:tag('td')
		:tag('span')
			:addClass(styleClass)
			:addClass('brkts-popup-mapveto-vetotype')
			:wikitext(vetoText)
	return self
end

function MapVeto:addColumnVetoMap(row,map)
	row:tag('td'):wikitext(map):done()
	return self
end

function MapVeto:create()
	return self.root
end

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)
	local frame = mw.getCurrentFrame()

	local matchSummary = MatchSummary:init('480px')
	matchSummary:header(CustomMatchSummary._createHeader(frame, match))
				:body(CustomMatchSummary._createBody(frame, match))

	if match.comment then
		matchSummary:comment(MatchSummary.Comment():content(match.comment))
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	if not Table.isEmpty(vods) then
		local footer = MatchSummary.Footer()

		for index, vod in pairs(vods) do
			footer:addElement(Template.safeExpand(frame, 'vodlink', {
				gamenum = index,
				vod = vod,
				source = vod.url
			}))
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(frame, match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
	      :leftScore(header:createScore(match.opponents[1]))
	      :rightScore(header:createScore(match.opponents[2]))
	      :rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(frame, match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= _EPOCH_TIME_EXTENDED and match.date ~= _EPOCH_TIME) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMap(frame, game))
		end
	end

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

	return body
end

function CustomMatchSummary._createMap(frame, game)
	local row = MatchSummary.Row()

	local team1Agents, team2Agents

	if not Table.isEmpty(game.participants) then
		team1Agents = Agents():setLeft()
		team2Agents = Agents():setRight()

		for player = 1, 5 do
			local playerStats = game.participants['1_' .. player]
			if playerStats ~= nil then
				team1Agents:add(frame, playerStats['agent'])
			end
		end

		for player = 1, 5 do
			local playerStats = game.participants['2_' .. player]
			if playerStats ~= nil then
				team2Agents:add(frame, playerStats['agent'])
			end
		end

	end

	local score1, score2

	local extradata = game.extradata
	score1 = Score():setLeft()
	score2 = Score():setRight()

	score1:setMapScore(game.scores[1])
	score2:setMapScore(game.scores[2])

	if not Table.isEmpty(extradata) then
		-- Detailed scores
		local team1Halfs = extradata.t1halfs or {}
		local team2Halfs = extradata.t2halfs or {}
		local firstSide = (extradata.t1firstside or ''):lower()
		local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)

		score1:setFirstRoundScore(firstSide, team1Halfs[firstSide])
		score1:setSecondRoundScore(oppositeSide, team1Halfs[oppositeSide])

		-- TODO: Overtime support

		score2:setFirstRoundScore(oppositeSide, team2Halfs[oppositeSide])
		score2:setSecondRoundScore(firstSide, team2Halfs[firstSide])
	end

	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	if team1Agents ~= nil then
		row:addElement(team1Agents:create())
	end
	row:addElement(score1:create())

	local centerNode = mw.html.create('div')
	centerNode  :addClass('brkts-popup-spaced')
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

function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced')

	if isWinner then
		container:node('[[File:GreenCheck.png|14x14px|link=]]')
		return container
	end

	container:node('[[File:NoCheck.png|link=]]')
	return container
end

return CustomMatchSummary
