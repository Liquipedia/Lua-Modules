---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchSummary = require('Module:MatchSummary/Base')
local OperatorIcon = require('Module:OperatorIcon')
local Table = require('Module:Table')
local Template = require('Module:Template')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local _GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local _ROUND_ICONS = {
	atk = '[[File:R6S Para Bellum atk logo.png|14px|link=]]',
	def = '[[File:R6S Para Bellum def logo.png|14px|link=]]',
	otatk = '[[File:R6S Para Bellum atk logo ot rounds.png|11px|link=]]',
	otdef = '[[File:R6S Para Bellum def logo ot rounds.png|11px|link=]]',
}
local _ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local _ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'
local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'File:Preview Icon.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport.png', text = 'LiveReport.png'},
	siegegg = {icon = 'File:SiegeGG icon.png', text = 'SiegeGG Match Page'},
	opl = {icon = 'File:OPL Icon.png', text = 'OPL Match Page'},
	esl = {icon = 'File:ESL icon.png', text = 'Match page on ESL'},
	faceit = {icon = 'File:FACEIT-icon.png', text = 'Match page on FACEIT'},
	lpl = {icon = 'File:LPL Play icon.png', text = 'Match page on LPL Play'},
	r6esports = {icon = 'File:Copa Elite Six icon.png', text = 'R6 Esports LATAM Match Page'},
	stats = {icon = 'File:Match_Info_Stats.png', text = 'Match Statistics'},
}

local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

-- Operator Bans Class

local OperatorBans = Class.new(
	function(self)
		self.root = mw.html.create('table')
		self.text = ''
	end
)

function OperatorBans:setLeft()
	self.root
		:addClass('brkts-popup-body-operator-bans')
		:css('float', 'left')

	return self
end

function OperatorBans:setRight()
	self.root
		:addClass('brkts-popup-body-operator-bans')
		:css('float', 'right')

	return self
end

function OperatorBans:add(operator)
	if Logic.isEmpty(operator) then
		return self
	end
	self.root
		:tag('tr')
			:tag('td')
				:css('padding', '0')
				:tag('div')
					:wikitext(OperatorIcon.getImage{operator,'50x50px'})
	return self
end

function OperatorBans:create()
	self.root:wikitext(self.text)
	return self.root
end

-- Score Class, both for the "big" score, and the halfs scores

local Score = Class.new(
	function(self)
		self.root = mw.html.create('div'):css('width','70px')
		self.table = self.root:tag('table'):css('line-height', '20px')
		self.top = mw.html.create('tr')
		self.bottom = mw.html.create('tr')
	end
)

function Score:setLeft()
	self.root
		:css('text-align', 'left')

	return self
end

function Score:setRight()
	self.root
		:css('text-align', 'right')

	return self
end

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

function Score:setFirstRoundScore(side, score, isLeft)
	local icon = _ROUND_ICONS[side]
	if not isLeft then -- For right side, swap order of score and icon
		icon, score = score, icon
	end

	local roundScore = mw.html.create('td')
	roundScore  :addClass('brkts-popup-body-match-sidewins')
				:wikitext(icon)
				:wikitext(score or '')

	self.top:node(roundScore)
	return self
end

function Score:setSecondRoundScore(side, score, isLeft)
	local icon = _ROUND_ICONS[side]
	if not isLeft then -- For right side, swap order of score and icon
		icon, score = score, icon
	end

	local roundScore = mw.html.create('td')
	roundScore  :addClass('brkts-popup-body-match-sidewins')
				:wikitext(icon)
				:wikitext(score or '')

	self.bottom:node(roundScore)
	return self
end

function Score:setFirstOvertimeRoundScore(side, score, isLeft)
	local icon = _ROUND_ICONS['ot'..side]
	if not isLeft then -- For right side, swap order of score and icon
		icon, score = score, icon
	end

	local roundScore = mw.html.create('td')
	roundScore  :addClass('brkts-popup-body-match-sidewins-overtime')
				:wikitext(icon)
				:wikitext(score or '')

	self.top:node(roundScore)
	return self
end

function Score:setSecondOvertimeRoundScore(side, score, isLeft)
	local icon = _ROUND_ICONS['ot'..side]
	if not isLeft then -- For right side, swap order of score and icon
		icon, score = score, icon
	end

	local roundScore = mw.html.create('td')
	roundScore  :addClass('brkts-popup-body-match-sidewins-overtime')
				:wikitext(icon)
				:wikitext(score or '')

	self.bottom:node(roundScore)
	return self
end

function Score:addEmptyOvertime()
	local roundScore = mw.html.create('td'):css('width','20px')
	self.top:node(roundScore)
	self.bottom:node(roundScore)
	return self
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
		map = '[['..map..'/siege|'..map..']]'
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
		map1 = '[['..map1..'/siege|'..map1..']]'
	end
	if Logic.isEmpty(map2) then
		map2 = 'TBD'
	else
		map2 = '[['..map2..'/siege|'..map2..']]'
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


-- MVP Class
local MVP = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-footer'):addClass('brkts-popup-mvp')
		self.players = {}
		self.points = nil
	end
)

function MVP:addPlayer(player)
	if not Logic.isEmpty(player) then
		table.insert(self.players, player)
	end
	return self
end

function MVP:setPoints(points)
	if Logic.isNumeric(points) then
		self.points = points
	end
	return self
end

function MVP:create()
	local span = mw.html.create('span')
	span:wikitext(#self.players > 1 and 'MVPs: ' or 'MVP: ')
	for index, player in ipairs(self.players) do
		if index > 1 then
			span:wikitext(', ')
		end
		span:wikitext('[['..player..']]')
	end
	if self.points and self.points ~= 1 then
		span:wikitext(' ('.. self.points ..'pts)')
	end
	self.root:node(span)
	return self.root
end

local CustomMatchSummary = {}


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)
	mw.logObject(match)
	local frame = mw.getCurrentFrame()

	local matchSummary = MatchSummary():init()
	matchSummary.root:css('flex-wrap', 'unset') -- temporary workaround to fix height, taken from RL

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		comment.root:css('display', 'block'):css('text-align', 'center')
		matchSummary:comment(comment)
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	match.links.lrthread = match.lrthread
	match.links.vod = match.vod
	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Game Vods
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

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()
	header  :left(CustomMatchSummary._createOpponent(match.opponents[1], 'left'))
			:right(CustomMatchSummary._createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact then
		-- dateIsExact means we have both date and time. Show countdown
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	elseif match.date ~= _EPOCH_TIME_EXTENDED then
		-- if match is not epoch=0, we have a date, so display the date
		-- TODO:Less code duplication, all html stuff is a copy from DisplayHelper.MatchCountdownBlock
		body:addRow(MatchSummary.Row():addElement(
			mw.html.create('div'):addClass('match-countdown-block')
				:css('text-align', 'center')
				-- Workaround for .brkts-popup-body-element > * selector
				:css('display', 'block')
				:wikitext(mw.getContentLanguage():formatDate('F d, Y', match.date))
		))
	end

	--local matchPageElement = mw.html.create('center')
	--matchPageElement   :wikitext('[[Match:ID_' .. match.matchId .. '|Match Page]]')
	--				:css('display', 'block')
	--				:css('margin', 'auto')
	--body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement))

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMap(game))
		end
	end

	-- Add Match MVP(s)
	if match.extradata.mvp then
		local mvpData = match.extradata.mvp
		if not Table.isEmpty(mvpData) and mvpData.players then
			local mvp = MVP()
			for _, player in ipairs(mvpData.players) do
				mvp:addPlayer(player)
			end
			mvp:setPoints(mvpData.points)

			body:addRow(mvp)
		end

	end

	-- Add the Map Vetoes
	if match.extradata.mapveto then
		local vetoData = match.extradata.mapveto
		if vetoData then
			local mapVeto = MapVeto()

			for _,vetoRound in ipairs(vetoData) do
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

function CustomMatchSummary._createMap(game)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score():setRight()

	-- Score Team 1
	team1Score:setMapScore(game.scores[1])

	-- Detailed scores
	local team1Halfs = extradata.t1halfs or {}
	local team2Halfs = extradata.t2halfs or {}
	local firstSides = extradata.t1firstside or {}

	local firstSide = (firstSides[1] or ''):lower()
	local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)

	if not Logic.isEmpty(firstSide) then
		-- Regular Time for Team 1
		team1Score:setFirstRoundScore(firstSide, team1Halfs[firstSide], true)
		team1Score:setSecondRoundScore(oppositeSide, team1Halfs[oppositeSide], true)

		-- Overtime for both, if applicable
		local firstSideOvertime = firstSides.ot
		local oppositeSideOvertime = CustomMatchSummary._getOppositeSide(firstSideOvertime)

		if not Logic.isEmpty(firstSideOvertime) then
			team1Score:setFirstOvertimeRoundScore(firstSideOvertime, team1Halfs['ot'..firstSideOvertime], true)
			team1Score:setSecondOvertimeRoundScore(oppositeSideOvertime, team1Halfs['ot'..oppositeSideOvertime], true)

			team2Score:setFirstOvertimeRoundScore(oppositeSideOvertime, team2Halfs['ot'..oppositeSideOvertime], false)
			team2Score:setSecondOvertimeRoundScore(firstSideOvertime, team2Halfs['ot'..firstSideOvertime], false)
		else
			team1Score:addEmptyOvertime()
			team2Score:addEmptyOvertime()
		end

		-- Regular Time for Team 2
		team2Score:setFirstRoundScore(oppositeSide, team2Halfs[oppositeSide], false)
		team2Score:setSecondRoundScore(firstSide, team2Halfs[firstSide], false)
	end

	-- Score Team 2
	team2Score:setMapScore(game.scores[2])

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
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(team1Score:create())

	local centerNode = mw.html.create('div')
	centerNode  :addClass('brkts-popup-spaced')
				:wikitext('[[' .. game.map .. ']]')
				:css('text-align', 'center')
				:css('padding','5px 2px')
				:css('flex-grow','1')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	row:addElement(centerNode)
	row:addElement(team2Score:create())
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
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

	row:addClass('brkts-popup-body-game'):css('font-size', '85%'):css('overflow', 'hidden')

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

function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if isWinner then
		container:node(_GREEN_CHECK)
	else
		container:node(_NO_CHECK)
	end

	return container
end

function CustomMatchSummary._createOpponent(opponent, side)
	return OpponentDisplay.BlockOpponent({
		flip = side == 'left',
		opponent = opponent,
		overflow = 'wrap',
		teamStyle = 'short',
	})
end

return CustomMatchSummary
