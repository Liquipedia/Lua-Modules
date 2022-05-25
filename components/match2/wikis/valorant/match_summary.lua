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

local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	vlr = {icon = 'File:VLR icon.png', text = 'Matchpage and Stats on VLR'},
}

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

	match.links.vod = match.vod
	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		for index, vod in pairs(vods) do
			footer:addElement(Template.safeExpand(frame, 'vodlink', {
				gamenum = index,
				vod = vod,
				source = vod.url
			}))
		end

		-- Match Vod + other links
		local buildLink = function (linktype, link)
			local icon, text = _LINK_DATA[linktype].icon, _LINK_DATA[linktype].text
			return '[['..icon..'|link='..link..'|15px|'..text..']]'
		end

		for linktype, link in pairs(match.links) do
			footer:addElement(buildLink(linktype,link))
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

	local streamElement = DisplayHelper.MatchCountdownBlock(match)
	body:addRow(MatchSummary.Row():addElement(streamElement))

	local matchPageElement = mw.html.create('center')
	matchPageElement   :wikitext('[[Match:ID_' .. match.matchId .. '|Match Page]]')
					:css('display', 'block')
					:css('margin', 'auto')
	body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement))

	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMap(frame, game))
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
		score1:setFirstRoundScore(extradata.op1startside, extradata.half1score1)
		score1:setSecondRoundScore(
			CustomMatchSummary._getOppositeSide(extradata.op1startside), extradata.half2score1)

		score2:setFirstRoundScore(
			CustomMatchSummary._getOppositeSide(extradata.op1startside), extradata.half1score2)
		score2:setSecondRoundScore(extradata.op1startside, extradata.half2score2)
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
