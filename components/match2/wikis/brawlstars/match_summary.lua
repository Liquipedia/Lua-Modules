---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')
local MapTypeIcon = require('Module:MapType')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local BrawlerIcon = require('Module:BrawlerIcon')
local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Json = require('Module:Json')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local htmlCreate = mw.html.create

local _GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local _ICONS = {
	check = _GREEN_CHECK,
}
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'LiveReport.png'},
}


local CustomMatchSummary = {}


-- Brawler Pick/Ban Class
local Brawler = Class.new(
	function(self, options)
		options = options or {}
		self.isBan = options.isBan
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

function Brawler:createHeader(text)
	self.table:tag('tr')
		:tag('th'):css('width','40%'):wikitext(''):done()
		:tag('th'):css('width','20%'):wikitext(self.isBan and 'Bans' or 'Picks'):done()
		:tag('th'):css('width','40%'):wikitext(''):done()
	return self
end

function Brawler:row(brawlerData, gameNumber, numberBrawlers, date)
	if numberBrawlers > 0 then
		self.table:tag('tr')
			:tag('td')
				:node(self:_opponentBrawlerDisplay(brawlerData[1], numberBrawlers, false, date))
			:tag('td')
				:node(mw.html.create('div')
					:wikitext(Abbreviation.make(
							'Set ' .. gameNumber,
							(self.isBan and 'Bans' or 'Picks') .. ' in set ' .. gameNumber
						)
					)
				)
			:tag('td')
				:node(self:_opponentBrawlerDisplay(brawlerData[2], numberBrawlers, true, date))
	end

	return self
end

function Brawler:_opponentBrawlerDisplay(brawlerData, numberOfBrawlers, flip, date)
	local opponentBrawlerDisplay = {}

	for index = 1, numberOfBrawlers do
		local brawlerDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. (flip and 'red' or 'blue'))
			:css('float', flip and 'right' or 'left')
			:node(BrawlerIcon._getImage{
				brawler = brawlerData[index],
				class = 'brkts-champion-icon',
				date = date,
			})
		if index == 1 then
			brawlerDisplay:css('padding-left', '2px')
		elseif index == numberOfBrawlers then
			brawlerDisplay:css('padding-right', '2px')
		end
		table.insert(opponentBrawlerDisplay, brawlerDisplay)
	end

	if flip then
		opponentBrawlerDisplay = Array.reverse(opponentBrawlerDisplay)
	end

	local display = mw.html.create('div')
	if self.isBan then
		display:addClass('brkts-popup-side-shade-out')
		display:css('padding-' .. (flip and 'right' or 'left'), '4px')
	end

	for _, item in ipairs(opponentBrawlerDisplay) do
		display:node(item)
	end

	return display
end

function Brawler:create()
	return self.root
end

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()

	matchSummary:header(CustomMatchSummary._createHeader(match))
		:body(CustomMatchSummary._createBody(match))

	-- comment
	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	-- footer
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
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		-- Match Vod + other links
		local buildLink = function (linkType, link)
			local linkData = _LINK_DATA[linkType]
			if not linkData then
				mw.log('linkType "' .. linkType .. '" is not supported by Module:MatchSummary')
			else
				return '[[' .. linkData.icon .. '|link=' .. link .. '|15px|' .. linkData.text .. ']]'
			end
		end

		for linkType, link in pairs(match.links) do
			footer:addElement(buildLink(linkType,link))
		end

		matchSummary:footer(footer)
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

	if match.dateIsExact or (match.date ~= _EPOCH_TIME_EXTENDED and match.date ~= _EPOCH_TIME) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMapRow(game))
		end
	end

	-- Add Match MVP(s)
	local mvpInput = match.extradata.mvp
	if mvpInput then
		local mvpData = mw.text.split(mvpInput or '', ',')
		if String.isNotEmpty(mvpData[1]) then
			local mvp = MatchSummary.Mvp()
			for _, player in ipairs(mvpData) do
				if String.isNotEmpty(player) then
					mvp:addPlayer(player)
				end
			end

			body:addRow(mvp)
		end
	end

	-- Pre-Process Brawler picks
	local showGamePicks = {}
	for gameIndex, game in ipairs(match.games) do
		local pickData = {{}, {}}
		local numberOfPicks = game.extradata.maximumpickindex
		local participants = game.participants
		for index = 1, numberOfPicks do
			if not Table.isEmpty(participants['1_' .. index]) then
				pickData[1][index] = participants['1_' .. index].brawler
			end
			if not Table.isEmpty(participants['2_' .. index]) then
				pickData[2][index] = participants['2_' .. index].brawler
			end
		end

		if numberOfPicks > 0 then
			pickData.numberOfPicks = numberOfPicks
			showGamePicks[gameIndex] = pickData
		end
	end

	-- Add the Brawler picks
	if not Table.isEmpty(showGamePicks) then
		local brawler = Brawler({isBan = false})

		for gameIndex, pickData in ipairs(showGamePicks) do
			brawler:row(pickData, gameIndex, pickData.numberOfPicks, match.date)
		end

		body:addRow(brawler)
	end

	-- Pre-Process Brawler bans
	local showGameBans = {}
	for gameIndex, game in ipairs(match.games) do
		local extradata = game.extradata
		local bans = Json.parseIfString(extradata.bans or '{}')
		if not Table.isEmpty(bans) then
			bans.numberOfBans = math.max(#bans.team1, #bans.team2)
			if bans.numberOfBans > 0 then
				bans[1] = bans.team1
				bans[2] = bans.team2
				showGameBans[gameIndex] = bans
			end
		end
	end

	-- Add the Brawler bans
	if not Table.isEmpty(showGameBans) then
		local brawler = Brawler({isBan = true})

		for gameIndex, banData in ipairs(showGameBans) do
			brawler:row(banData, gameIndex, banData.numberOfBans, match.date)
		end

		body:addRow(brawler)
	end

	return body
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] or ''
	return htmlCreate('div'):wikitext(score)
end

function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = htmlCreate('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, 'check'))

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = htmlCreate('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'
	if String.isNotEmpty(game.extradata.maptype) then
		mapDisplay = MapTypeIcon.display(game.extradata.maptype) .. mapDisplay
	end
	return mapDisplay
end

function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = htmlCreate('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(_ICONS[iconType])
	else
		container:node(_NO_CHECK)
	end

	return container
end

return CustomMatchSummary
