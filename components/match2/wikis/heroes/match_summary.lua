---
-- @Liquipedia
-- wiki=heroes
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local ExternalLinks = require('Module:ExternalLinks')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MAX_NUM_BANS = 3
local NUM_CHAMPIONS_PICK = 5

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'
local MAP_VETO_START = '<b>Start Map Veto</b>'
local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'
local FP = Abbreviation.make('First Pick', 'First Pick for Heroes on this map')
local TBD = Abbreviation.make('TBD', 'To Be Determined')

local VETO_TYPE_TO_TEXT = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',
}

-- Champion Ban Class
---@class HeroesOfTheStormHeroBan: MatchSummaryRowInterface
---@operator call: HeroesOfTheStormHeroBan
---@field root Html
---@field table Html
local ChampionBan = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

---@return HeroesOfTheStormHeroBan
function ChampionBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','40%'):wikitext(''):done()
		:tag('th'):css('width','20%'):wikitext('Bans'):done()
		:tag('th'):css('width','40%'):wikitext(''):done()
	return self
end

---@param banData {numberOfBans: integer, [1]: table, [2]: table}
---@param gameNumber integer
---@param date string
---@return HeroesOfTheStormHeroBan
function ChampionBan:banRow(banData, gameNumber, date)
	if Logic.isEmpty(banData) then
		return self
	end
	self.table:tag('tr')
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[1], banData.numberOfBans, date, false, true))
		:tag('td')
			:node(mw.html.create('div')
				:wikitext(Abbreviation.make(
							'Game ' .. gameNumber,
							'Bans in game ' .. gameNumber
						)
					)
				)
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[2], banData.numberOfBans, date, true, true))
	return self
end

---@return Html
function ChampionBan:create()
	return self.root
end

-- Map Veto Class
---@class HeroesOfTheStormMapVeto: MatchSummaryRowInterface
---@operator call: HeroesOfTheStormMapVeto
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

---@return HeroesOfTheStormMapVeto
function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

---@param firstVeto number?
---@param format string?
---@return HeroesOfTheStormMapVeto
function MapVeto:vetoStart(firstVeto, format)
	format = format and ('Veto format: ' .. format) or nil
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = MAP_VETO_START
		textCenter = ARROW_LEFT
		textRight = format
	elseif firstVeto == 2 then
		textLeft = format
		textCenter = ARROW_RIGHT
		textRight = MAP_VETO_START
	else return self end

	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()

	return self
end

---@param map1 string?
---@param map2 string?
---@return string, string
function MapVeto._displayMaps(map1, map2)
	if Logic.isEmpty(map1) and Logic.isEmpty(map2) then
		return TBD, TBD
	end

	return Logic.isEmpty(map1) and FP or ('[[' .. map1 .. ']]'),
		Logic.isEmpty(map2) and FP or ('[[' .. map2 .. ']]')
end

---@param vetoType string?
---@param map1 string?
---@param map2 string?
---@return HeroesOfTheStormMapVeto
function MapVeto:addRound(vetoType, map1, map2)
	map1, map2 = MapVeto._displayMaps(map1, map2)

	local vetoText = VETO_TYPE_TO_TEXT[vetoType]

	if not vetoText then return self end

	local class = 'brkts-popup-mapveto-' .. vetoType

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoMap(row, map1)
	self:addColumnVetoType(row, class, vetoText)
	self:addColumnVetoMap(row, map2)

	self.table:node(row)
	return self
end

---@param row Html
---@param styleClass string
---@param vetoText string
---@return HeroesOfTheStormMapVeto
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
---@return HeroesOfTheStormMapVeto
function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map):done()
	return self
end

---@return Html
function MapVeto:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	if Table.isNotEmpty(match.links) then
		footer:addElement(ExternalLinks.print(match.links))
	end

	return footer
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

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex, match.date)
		if rowDisplay then
			body:addRow(rowDisplay)
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

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	-- Pre-Process Champion Ban Data
	local championBanData = {}
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
			banData[1].color = extradata.team1side
			banData[2].color = extradata.team2side
			banData.numberOfBans = numberOfBans
			championBanData[gameIndex] = banData
		end
	end

	-- Add the Champion Bans
	if not Table.isEmpty(championBanData) then
		local championBan = ChampionBan()

		Array.forEach(match.games,function (_, gameIndex)
			championBan:banRow(championBanData[gameIndex], gameIndex, match.date)
		end)

		body:addRow(championBan)
	end

	-- Add the Map Vetoes
	if match.extradata.mapveto then
		local vetoData = match.extradata.mapveto
		if vetoData then
			local mapVeto = MapVeto()
			if vetoData[1] and vetoData[1].vetostart then
				mapVeto:vetoStart(tonumber(vetoData[1].vetostart), vetoData[1].format)
			end

			for _,vetoRound in ipairs(vetoData) do
				mapVeto:addRound(vetoRound.type, vetoRound.team1, vetoRound.team2)
			end

			body:addRow(mapVeto)
		end
	end

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return MatchSummaryRow?
function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local championsData = {{}, {}}
	local championsDataIsEmpty = true
	for champIndex = 1, NUM_CHAMPIONS_PICK do
		if String.isNotEmpty(extradata['team1champion' .. champIndex]) then
			championsData[1][champIndex] = extradata['team1champion' .. champIndex]
			championsDataIsEmpty = false
		end
		if String.isNotEmpty(extradata['team2champion' .. champIndex]) then
			championsData[2][champIndex] = extradata['team2champion' .. champIndex]
			championsDataIsEmpty = false
		end
		championsData[1].color = extradata.team1side
		championsData[2].color = extradata.team2side
	end

	if
		Logic.isEmpty(game.length) and
		Logic.isEmpty(game.winner) and
		championsDataIsEmpty
	then
		return nil
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '90%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[1], NUM_CHAMPIONS_PICK, date, false))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '120px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext('[[' .. game.map .. ']]')
		)
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[2], NUM_CHAMPIONS_PICK, date, true))

	if Logic.isNotEmpty(game.comment) or Logic.isNotEmpty(game.length) then
		game.length = Logic.nilIfEmpty(game.length)
		local commentContents = Array.append({},
			Logic.nilIfEmpty(game.comment),
			game.length and tostring(mw.html.create('span'):wikitext('Match Duration: ' .. game.length)) or nil
		)
		row
			:addElement(MatchSummary.Break():create())
			:addElement(mw.html.create('div')
				:css('margin', 'auto')
				:wikitext(table.concat(commentContents, '<br>'))
			)
	end

	return row
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '27px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if isWinner then
		container:node(GREEN_CHECK )
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param opponentChampionsData table
---@param numberOfChampions integer
---@param date string
---@param flip boolean?
---@param isBan boolean?
---@return Html
function CustomMatchSummary._opponentChampionsDisplay(opponentChampionsData, numberOfChampions, date, flip, isBan)
	local opponentChampionsDisplay = {}
	local color = opponentChampionsData.color or ''
	opponentChampionsData.color = nil

	for index = 1, numberOfChampions do
		local champDisplay = mw.html.create('div')
		:addClass('brkts-popup-side-color-' .. color)
		:css('float', flip and 'right' or 'left')
		:node(CharacterIcon.Icon{
			character = opponentChampionsData[index] or NO_CHARACTER,
			class = 'brkts-champion-icon',
			date = date,
		})
		if index == 1 then
			champDisplay:css('padding-left', '2px')
		elseif index == numberOfChampions then
			champDisplay:css('padding-right', '2px')
		end
		table.insert(opponentChampionsDisplay, champDisplay)
	end

	if flip then
		opponentChampionsDisplay = Array.reverse(opponentChampionsDisplay)
	end

	local display = mw.html.create('div')
	if isBan then
		display:addClass('brkts-popup-side-shade-out')
		display:css('padding-' .. (flip and 'right' or 'left'), '4px')
	end

	for _, item in ipairs(opponentChampionsDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
