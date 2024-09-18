---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchPage = Lua.import('Module:MatchPage')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local Opponent = Lua.import('Module:Opponent')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK_TEAM = 5
local NUM_HEROES_PICK_SOLO = 1
local SIZE_HERO = '57x32px'
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'

-- Hero Ban Class
---@class DotaHeroBan: MatchSummaryRowInterface
---@operator call: DotaHeroBan
---@field root Html
---@field table Html
local HeroBan = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

---@return self
function HeroBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','35%'):wikitext(''):done()
		:tag('th'):css('width','30%'):wikitext('Bans'):done()
		:tag('th'):css('width','35%'):wikitext(''):done()
	return self
end

---@param banData {numberOfBans: integer, [1]: table, [2]: table}
---@param gameNumber integer
---@param numberOfBans integer
---@return self
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

---@return Html
function HeroBan:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

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

	return footer:addLinks(MatchLinks, match.links)
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

	if MatchPage.isEnabledFor(match) then
		local matchId = match.extradata.originalmatchid or match.matchId
		local matchPageElement = mw.html.create('center')
		matchPageElement:wikitext('[[Match:ID_' .. matchId .. '|Match Page]]')
						:css('display', 'block')
						:css('margin', 'auto')
		body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement):addClass('brkts-popup-mvp'))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex)
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
		local extradata = game.extradata or {}
		local banData = {{}, {}}
		local numberOfBans = 0
		for index = 1, MAX_NUM_BANS do
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

	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local numberOfHeroes = NUM_HEROES_PICK_TEAM
	if game.mode == Opponent.solo then
		numberOfHeroes = NUM_HEROES_PICK_SOLO
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
			title = Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length',
			text = Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
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

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(isWinner) then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param args table
---@return string
function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

---@param opponentHeroesData table
---@param numberOfHeroes integer
---@param flip boolean?
---@param isBan boolean?
---@return Html
function CustomMatchSummary._opponentHeroesDisplay(opponentHeroesData, numberOfHeroes, flip, isBan)
	local opponentHeroesDisplay = {}
	local color = opponentHeroesData.side or ''

	for index = 1, numberOfHeroes do
		local heroDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. color)
			:addClass('brkts-popup-side-hero')
			:addClass('brkts-popup-side-hero-hover')
			:node(CharacterIcon.Icon{
				character = opponentHeroesData[index] or NO_CHARACTER,
				size = SIZE_HERO,
			})
		if numberOfHeroes == NUM_HEROES_PICK_SOLO then
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
		:addClass('brkts-popup-body-element-thumbs-' .. (flip and 'right' or 'left'))
	for _, item in ipairs(opponentHeroesDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
