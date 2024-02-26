---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local ExternalLinks = require('Module:ExternalLinks')
local String = require('Module:StringUtils')
local Array = require('Module:Array')
local Abbreviation = require('Module:Abbreviation')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MAX_NUM_BANS = 5
local NUM_CHAMPIONS_PICK = 5

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'

-- Champion Ban Class
---@class PokemonChampionBan: MatchSummaryRowInterface
---@operator call: PokemonChampionBan
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

---@return self
function ChampionBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','40%'):wikitext(''):done()
		:tag('th'):css('width','20%'):wikitext('Bans'):done()
		:tag('th'):css('width','40%'):wikitext(''):done()
	return self
end

---@param banData {numberOfBans: integer, [1]: table, [2]: table}
---@param gameNumber integer
---@param numberOfBans integer
---@param date string
---@return self
function ChampionBan:banRow(banData, gameNumber, numberOfBans, date)
	self.table:tag('tr')
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[1], numberOfBans, date, false, true))
		:tag('td')
			:node(mw.html.create('div')
				:wikitext(Abbreviation.make(
					'Game ' .. gameNumber,
					'Bans in game ' .. gameNumber
				))
			)
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[2], numberOfBans, date, true, true))
	return self
end

---@return Html
function ChampionBan:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '420px', teamStyle = 'bracket'})
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

		for gameIndex, banData in ipairs(championBanData) do
			championBan:banRow(banData, gameIndex, banData.numberOfBans, match.date)
		end

		body:addRow(championBan)
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

	local getChampsForTeam = function(team)
		local getChampFromIndex = function(champIndex)
			return champIndex, String.nilIfEmpty(extradata['team' .. team .. 'champion' .. champIndex])
		end
		return Table.map(Array.range(1, NUM_CHAMPIONS_PICK), getChampFromIndex)
	end
	local championsData = Array.map(Array.range(1, 2), getChampsForTeam)--[[@as table]]
	local championsDataIsEmpty = Array.all(championsData, Table.isEmpty)
	championsData[1].color = extradata.team1side
	championsData[2].color = extradata.team2side

	if Table.isEmpty(game.scores) and Logic.isEmpty(game.winner) and championsDataIsEmpty then
		return nil
	end

	row	:addClass('brkts-popup-body-game')
		:css('font-size', '85%')
		:css('overflow', 'hidden')

	local score
	if not Table.isEmpty(game.scores) then
		score = table.concat(game.scores, '-')
	end

	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[1], NUM_CHAMPIONS_PICK, date, false))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(Abbreviation.make(
			score or ('Game ' .. gameIndex),
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Map Scores'
		))
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[2], NUM_CHAMPIONS_PICK, date, true))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
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
		:css('line-height', '27px')
		:css('margin-left', '3%')
		:css('margin-right', '3%')

	if isWinner then
		container:node(GREEN_CHECK)
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
	local color = Table.extract(opponentChampionsData, 'color') or ''
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
		display:addClass('brkts-popup-side-shade-out' .. (flip and '-flipped' or ''))
	end

	for _, item in ipairs(opponentChampionsDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
