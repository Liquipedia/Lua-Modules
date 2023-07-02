---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local HeroIcon = require('Module:ChampionIcon')
local MatchLinks = mw.loadData('Module:MatchLinks')
local Table = require('Module:Table')
local String = require('Module:StringUtils')
local Array = require('Module:Array')
local VodLink = require('Module:VodLink')

local BigMatch = Lua.import('Module:BigMatch', {requireDevIfEnabled = true})
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local _MAX_NUM_BANS = 7
local _NUM_HEROES_PICK_TEAM = 5
local _NUM_HEROES_PICK_SOLO = 1
local _GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'

-- Hero Ban Class
local HeroBan = Class.new(
	function(self, date)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self.date = date
		self:createHeader()
	end
)

function HeroBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width', '40%'):wikitext(''):done()
		:tag('th'):css('width', '20%'):wikitext('Bans'):done()
		:tag('th'):css('width', '40%'):wikitext(''):done()
	return self
end

function HeroBan:banRow(banData, gameNumber, numberOfBans)
	self.table:tag('tr')
		:tag('td'):css('float', 'left')
			:node(CustomMatchSummary._opponentHeroesDisplay(banData[1], numberOfBans, true, self.date))
		:tag('td'):css('font-size', '80%'):node(mw.html.create('div')
			:wikitext(CustomMatchSummary._createAbbreviation{
				title = 'Bans in game ' .. gameNumber,
				text = 'Game ' .. gameNumber,
			})
		)
		:tag('td'):css('float', 'right')
			:node(CustomMatchSummary._opponentHeroesDisplay(banData[2], numberOfBans, true, self.date))
	return self
end

function HeroBan:create()
	return self.root
end


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init('400px')

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if not Logic.isEmpty(game.vod) then
			vods[index] = game.vod
		end
	end
	match.links.vod = match.vod

	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Match Vod + other links
		local buildLink = function (link, icon, text)
			return '[[File:'..icon..'|link='..link..'|15px|'..text..']]'
		end

		for linkType, link in pairs(match.links) do
			if not MatchLinks[linkType] then
				mw.log('Unknown link: ' .. linkType)
			else
				footer:addElement(buildLink(link, MatchLinks[linkType].icon, MatchLinks[linkType].text))
			end
		end

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left', 'bracket'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right', 'bracket'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.epochZero then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	if BigMatch.isEnabledFor(match) then
		local matchPageElement = mw.html.create('center')
		matchPageElement:wikitext('[[Match:ID_' .. match.matchId .. '|Match Page]]')
						:css('display', 'block')
						:css('margin', 'auto')
		body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement):addClass('brkts-popup-mvp'))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex, match.date)
		body:addRow(rowDisplay)
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
		local heroBan = HeroBan(match.date)

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

function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local numberOfHeroes = _NUM_HEROES_PICK_TEAM
	if game.mode == Opponent.solo then
		numberOfHeroes = _NUM_HEROES_PICK_SOLO
	end

	local heroesData = {{}, {}}
	for heroIndex = 1, numberOfHeroes do
		if String.isNotEmpty(extradata['team1champion' .. heroIndex]) then
			heroesData[1][heroIndex] = extradata['team1champion' .. heroIndex]
		end
		if String.isNotEmpty(extradata['team2champion' .. heroIndex]) then
			heroesData[2][heroIndex] = extradata['team2champion' .. heroIndex]
		end
		heroesData[1].side = extradata.team1side
		heroesData[2].side = extradata.team2side
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentHeroesDisplay(heroesData[1], numberOfHeroes, false, date))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(CustomMatchSummary._createAbbreviation{
			title = String.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length',
			text = String.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
		})
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentHeroesDisplay(heroesData[2], numberOfHeroes, true, date))

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
		:addClass('brkts-popup-body-element-vertical-centered')
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

function CustomMatchSummary._opponentHeroesDisplay(opponentHeroesData, numberOfHeroes, flip, date)
	local opponentHeroesDisplay = {}
	local color = opponentHeroesData.side or ''

	for index = 1, numberOfHeroes do
		local heroDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. color)
			:css('float', flip and 'right' or 'left')
			:node(HeroIcon._getImage{opponentHeroesData[index], date = date})
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
		:addClass('brkts-popup-body-element-thumbs')
		:addClass('brkts-champion-icon')

	for _, item in ipairs(opponentHeroesDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
