---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'

local EPOCH_TIME = '1970-01-01 00:00:00'
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local TBD = 'TBD'

-- Score Class
local Score = Class.new(
	function(self)
		self.root = mw.html.create('div'):css('width','70px'):css('text-align', 'center')
		self.table = self.root:tag('table'):css('line-height', '29px')
		self.top = mw.html.create('tr')
		self.bottom = mw.html.create('tr')
	end
)

function Score:setLeft()
	self.table:css('float', 'left')
	return self
end

function Score:setRight()
	self.table:css('float', 'right')
	return self
end

function Score:setMapScore(score)
	local mapScore = mw.html.create('td')
	mapScore
		:attr('rowspan', 2)
		:css('font-size', '16px')
		:css('width', '25px')
		:wikitext(score or '')

	self.top:node(mapScore)

	return self
end

function Score:setFirstHalfScore(score, side)
	local halfScore = mw.html.create('td')
	halfScore
		:addClass('brkts-popup-body-match-sidewins')
		:addClass('brkts-cs-score-color-' .. side)
		:wikitext(score)

	self.top:node(halfScore)
	return self
end

function Score:setSecondHalfScore(score, side)
	local halfScore = mw.html.create('td')
	halfScore
		:addClass('brkts-popup-body-match-sidewins')
		:addClass('brkts-cs-score-color-' .. side)
		:wikitext(score)

	self.bottom:node(halfScore)
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
		textCenter = ARROW_LEFT
	elseif firstVeto == 2 then
		textCenter = ARROW_RIGHT
		textRight = '\'\'\'Start Map Veto\'\'\''
	else return self end
	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()
	return self
end

function MapVeto:addDecider(map)
	map = Logic.emptyOr(map, TBD)

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')
	self:addColumnVetoMap(row, map)
	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')

	self.table:node(row)
	return self
end

function MapVeto:addRound(vetotype, map1, map2)
	map1 = Logic.emptyOr(map1, TBD)
	map2 = Logic.emptyOr(map2, TBD)

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

function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map):done()
	return self
end

function MapVeto:create()
	return self.root
end

local MatchStatus = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root
			:addClass('brkts-popup-comment')
			:css('white-space', 'normal')
			:css('font-size', '85%')
	end
)

function MatchStatus:content(content)
	self.root:node(content):node(MatchSummary.Break():create())
	return self
end

function MatchStatus:create()
	return self.root
end

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()
	matchSummary.root:css('flex-wrap', 'unset') -- workaround to fix height

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		comment.root:css('display', 'block'):css('text-align', 'center')
		matchSummary:comment(comment)
	end

	local vods = {}
	if Logic.isNotEmpty(match.links.vod2) then
		for _, vod2 in ipairs(match.links.vod2) do
			vods[vod2[2] + 100] = vod2[1]
		end
	end
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) or not Logic.isEmpty(match.vod) then
		matchSummary:footer(CustomMatchSummary._createFooter(match, vods))
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= EPOCH_TIME_EXTENDED and match.date ~= EPOCH_TIME) then
		if Logic.isNotEmpty(match.extradata.status) then
			match.stream = {rawdatetime = true}
		end
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMap(game))
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
					mapVeto:addDecider(CustomMatchSummary._createMapLink(vetoRound.decider, match.game))
				else
					mapVeto:addRound(vetoRound.type,
										CustomMatchSummary._createMapLink(vetoRound.team1, match.game),
										CustomMatchSummary._createMapLink(vetoRound.team2, match.game))
				end
			end

			body:addRow(mapVeto)
		end
	end

	-- Match Status (postponed/ cancel(l)ed)
	if match.extradata.status then
		local matchStatus = MatchStatus()
		matchStatus:content('\'\'\'Match ' .. mw.getContentLanguage():ucfirst(match.extradata.status) .. '\'\'\'')
		body:addRow(matchStatus)
	end

	return body
end

function CustomMatchSummary._createFooter(match, vods)
	local footer = MatchSummary.Footer()

	local separator = '<b>·</b>'

	local function addFooterLink(icon, iconDark, url, label, index)
		if icon == 'stats' then
			icon = index ~= 0 and 'Match Info Stats' .. index .. '.png' or 'Match Info Stats.png'
		end
		if index > 0 then
			label = label .. ' for Game ' .. index
		end

		icon = 'File:' .. icon
		if iconDark then
			iconDark = 'File:' .. iconDark
		end

		footer:addLink(url, icon, iconDark, label)
	end

	local function addVodLink(gamenum, vod, htext)
		if vod then
			footer:addElement(VodLink.display{
				gamenum = gamenum,
				vod = vod,
				htext = htext
			})
		end
	end

	-- Match vod
	if vods[100] then
		addVodLink(nil, match.vod, 'Watch VOD ' .. '(part 1)')
		addVodLink(nil, vods[100], 'Watch VOD ' .. '(part 2)')
	else
		addVodLink(nil, match.vod, nil)
	end

	-- Game Vods
	for index, vod in pairs(vods) do
		if index < 100 then
			if vods[index + 100] then
				addVodLink(index, vod, 'Watch Game ' .. index .. ' (part 1)')
				addVodLink(index, vods[index + 100], 'Watch Game ' .. index .. ' (part 2)')
			else
				addVodLink(index, vod, nil)
			end
		end
	end

	if Table.isNotEmpty(match.links) then
		if Logic.isNotEmpty(vods) or match.vod then
			footer:addElement(separator)
		end
	else
		return footer
	end

	--- Platforms is used to keep the order of the links in footer
	local platforms = mw.loadData('Module:MatchExternalLinks')
	local links = match.links

	local insertDotNext = false
	local iconsInserted = 0

	for _, platform in ipairs(platforms) do
		if Logic.isNotEmpty(platform) then
			local link = links[platform.name]
			if link then
				if insertDotNext then
					insertDotNext = false
					iconsInserted = 0
					footer:addElement(separator)
				end

				local icon = platform.icon
				local iconDark = platform.iconDark
				local label = platform.label
				local addGameLabel = platform.isMapStats and match.bestof and match.bestof > 1

				for _, val in ipairs(link) do
					addFooterLink(icon, iconDark, val[1], label, addGameLabel and val[2] or 0)
					iconsInserted = iconsInserted + 1
				end

				if platform.stats then
					for _, site in ipairs(platform.stats) do
						if links[site] then
							footer:addElement(separator)
							break
						end
					end
				end
			end
		else
			insertDotNext = iconsInserted > 0 and true or false
		end
	end

	return footer
end

function CustomMatchSummary._createMap(game)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score():setRight()

	-- Score Team 1
	team1Score:setMapScore(game.scores[1])

	local t1sides = extradata['t1sides'] or {}
	local t2sides = extradata['t2sides'] or {}
	local t1halfs = extradata['t1halfs'] or {}
	local t2halfs = extradata['t2halfs'] or {}

	local numberOfSides = #t2sides

	-- Insert team scores
	for sideIndex, side in ipairs(t1sides) do
		-- Team 1 scores inserted from 1 .. n
		if math.fmod(sideIndex, 2) == 1 then
			team1Score:setFirstHalfScore(t1halfs[sideIndex], side)
		else
			team1Score:setSecondHalfScore(t1halfs[sideIndex], side)
		end

		-- Team 2 scores inserted from n .. 1
		local t2SideIndex = numberOfSides - sideIndex + 1
		local oppositeSide = t2sides[t2SideIndex]
		if math.fmod(t2SideIndex, 2) == 1 then
			team2Score:setFirstHalfScore(t2halfs[t2SideIndex], oppositeSide)
		else
			team2Score:setSecondHalfScore(t2halfs[t2SideIndex], oppositeSide)
		end
	end

	-- Score Team 2
	team2Score:setMapScore(game.scores[2])

	-- Map Info
	local mapInfo = mw.html.create('div')
	mapInfo	:addClass('brkts-popup-spaced')
			:wikitext(CustomMatchSummary._createMapLink(game.map, game.game))
			:css('text-align', 'center')
			:css('padding','5px 2px')
			:css('flex-grow','1')

	if game.resultType == 'np' then
		mapInfo:addClass('brkts-popup-spaced-map-skip')
	elseif game.resultType == 'draw' then
		mapInfo:wikitext('<i>(Draw)</i>')
	end

	-- Build the HTML
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(team1Score:create())

	row:addElement(mapInfo)

	row:addElement(team2Score:create())
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game'):css('font-size', '85%'):css('overflow', 'hidden')

	return row
end

function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if isWinner then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

function CustomMatchSummary._createMapLink(map, game)
	if Logic.isNotEmpty(map) then
		if Logic.isNotEmpty(game) then
			return '[[' .. map .. '/' .. game .. '|' .. map .. ']]'
		else
			return '[[' .. map .. '|' .. map .. ']]'
		end
	end
	return ''
end

return CustomMatchSummary