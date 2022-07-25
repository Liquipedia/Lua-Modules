---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local HeroIcon = require('Module:HeroIcon')
local Table = require('Module:Table')
local String = require('Module:StringUtils')
local Array = require('Module:Array')
local VodLink = require('Module:VodLink')
local Opponent = require('Module:Opponent')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local _MAX_NUM_BANS = 7
local _NUM_HEROES_PICK_TEAM = 5
local _NUM_HEROES_PICK_SOLO = 1
local _SIZE_HERO = '57x32px'
local _GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
-- Normal links, from input/lpdb
local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'File:Preview Icon.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport.png', text = 'Live Report Thread'},
	recap = {icon = 'File:Writers Icon.png', text = 'Recap'},
	headtohead = {icon = 'File:Match Info Stats.png', text = 'Head-to-head statistics'},
	faceit = {icon = 'File:FACEIT-icon.png', text = 'FACEIT match room'},
}
-- Auto generated links from Publisher ID
local _AUTO_LINKS = {
	{icon = 'File:DOTABUFF-icon.png', url = 'https://www.dotabuff.com/matches/', name = 'DOTABUFF'},
	{icon = 'File:DatDota-icon.png', url = 'https://www.datdota.com/matches//', name = 'datDota'},
	{icon = 'File:Stratz-icon.png', url = 'https://stratz.com/en-us/match/', name = 'Stratz'},
}

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

-- Hero Ban Class
local HeroBan = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

function HeroBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','35%'):wikitext(''):done()
		:tag('th'):css('width','30%'):wikitext('Bans'):done()
		:tag('th'):css('width','35%'):wikitext(''):done()
	return self
end

function HeroBan:banRow(banData, gameNumber, numberOfBans)
	self.table:tag('tr')
		:tag('td'):attr('rowspan', '2'):node(mw.html.create('div')
			:wikitext(CustomMatchSummary._createAbbreviation{
				title = 'Bans in game ' .. gameNumber,
				text = 'Game ' .. gameNumber,
			})
		)
		:tag('td')
			:attr('colspan', '2')
			:node(CustomMatchSummary._opponentHeroesDisplay(banData[1], numberOfBans, true, true))
	self.table:tag('tr')
		:tag('td')
			:attr('colspan', '2')
			:node(CustomMatchSummary._opponentHeroesDisplay(banData[2], numberOfBans, true, true))
	return self
end

function HeroBan:create()
	return self.root
end


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId, _)

	local matchSummary = MatchSummary():init('400px')
	matchSummary.root:css('flex-wrap', 'unset')
	matchSummary.root:css('overflow', 'hidden')

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	local vods = {}
	local publisherids = {}
	for index, game in ipairs(match.games) do
		if not Logic.isEmpty(game.vod) then
			vods[index] = game.vod
		end
		if not String.isEmpty(game.extradata.publisherid) then
			publisherids[index] = game.extradata.publisherid
		end
	end

	match.links.vod = match.vod
	if
		Logic.readBool(match.extradata.headtohead) and
		match.opponents[1].type == Opponent.team and
		match.opponents[2].type == Opponent.team
	then
		local team1, team2 = string.gsub(match.opponents[1].name, ' ', '_'), string.gsub(match.opponents[2].name, ' ', '_')
		match.links.headtohead = tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
		'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' .. team1 ..
		'&Head_to_head_query%5Bopponent%5D=' .. team2 .. '&wpRunQuery=Run+query'
	end
	if not Table.isEmpty(vods) or not Table.isEmpty(publisherids) or not Table.isEmpty(match.links) then
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
		local buildLink = function (link, icon, text)
			return '[['..icon..'|link='..link..'|15px|'..text..']]'
		end

		for _, site in ipairs(_AUTO_LINKS) do
			for index, publisherid in pairs(publisherids) do
				local link = site.url .. publisherid
				local text = 'Game '..index..' on '.. site.name
				footer:addElement(buildLink(link, site.icon, text))
			end
		end

		for linkType, link in pairs(match.links) do
			if not _LINK_DATA[linkType] then
				mw.log('Unknown link: ' .. linkType)
			else
				footer:addElement(buildLink(link, _LINK_DATA[linkType].icon, _LINK_DATA[linkType].text))
			end
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
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex)
		body:addRow(rowDisplay)
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

	-- Pre-Process Hero Ban Data
	local showGameBans = {}
	for gameIndex, game in ipairs(match.games) do
		local extradata = game.extradata
		local banData = {{}, {}}
		local numberOfBans = 0
		for index = 1, _MAX_NUM_BANS do
			if String.isNotEmpty(extradata['team1ban' .. index]) then
				numberOfBans = index
				banData[1][index] = extradata['team1ban' .. index]
			end
			if String.isNotEmpty(extradata['team2ban' .. index]) then
				numberOfBans = index
				banData[2][index] = extradata['team2ban' .. index]
			end
		end

		if numberOfBans > 0 then
			banData[1].side = extradata.team1side
			banData[2].side = extradata.team2side
			banData.numberOfBans = numberOfBans
			showGameBans[gameIndex] = banData
		end
	end

	-- Add the Hero Bans
	if not Table.isEmpty(showGameBans) then
		local heroBan = HeroBan()

		for gameIndex in ipairs(match.games) do
			local banData = showGameBans[gameIndex]
			if banData then
				heroBan:banRow(banData, gameIndex, banData.numberOfBans)
			end
		end

		body:addRow(heroBan)
	end

	return body
end

function CustomMatchSummary._createGame(game, gameIndex)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local numberOfHeroes = _NUM_HEROES_PICK_TEAM
	if game.mode == Opponent.solo then
		numberOfHeroes = _NUM_HEROES_PICK_SOLO
	end
	local heroesData = {{}, {}}
	for heroIndex = 1, numberOfHeroes do
		if String.isNotEmpty(extradata['team1hero' .. heroIndex]) then
			heroesData[1][heroIndex] = extradata['team1hero' .. heroIndex]
		end
		if String.isNotEmpty(extradata['team2hero' .. heroIndex]) then
			heroesData[2][heroIndex] = extradata['team2hero' .. heroIndex]
		end
		heroesData[1].side = extradata.team1side
		heroesData[2].side = extradata.team2side
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')

	row:addElement(CustomMatchSummary._opponentHeroesDisplay(heroesData[1], numberOfHeroes, false))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(CustomMatchSummary._createAbbreviation{
			title = String.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length',
			text = String.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
		})
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentHeroesDisplay(heroesData[2], numberOfHeroes, true))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment:wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(isWinner) then
		container:node(_GREEN_CHECK)
	else
		container:node(_NO_CHECK)
	end

	return container
end

function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

function CustomMatchSummary._opponentHeroesDisplay(opponentHeroesData, numberOfHeroes, flip, isBan)
	local opponentHeroesDisplay = {}
	local color = opponentHeroesData.side or ''

	for index = 1, numberOfHeroes do
		local heroDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. color)
			:addClass('brkts-popup-side-hero')
			:addClass('brkts-popup-side-hero-hover')
			:css('float', flip and 'right' or 'left')
			:node(HeroIcon._getImage{
				hero = opponentHeroesData[index],
				size = _SIZE_HERO,
			})
		if numberOfHeroes == _NUM_HEROES_PICK_SOLO then
			if flip then
				heroDisplay:css('margin-right', '70px')
			else
				heroDisplay:css('margin-left', '70px')
			end
		end
		table.insert(opponentHeroesDisplay, heroDisplay)
	end

	if flip then
		opponentHeroesDisplay = Array.reverse(opponentHeroesDisplay)
	end

	local display = mw.html.create('div')
	for _, item in ipairs(opponentHeroesDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
