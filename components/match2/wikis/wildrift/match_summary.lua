---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Class = require('Module:Class')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ChampionIcon = require('Module:ChampionIcon')
local Table = require('Module:Table')
local ExternalLinks = require('Module:ExternalLinks')
local String = require('Module:StringUtils')
local Array = require('Module:Array')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MAX_NUM_BANS = 5
local NUM_CHAMPIONS_PICK = 5

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local EPOCH_TIME = '1970-01-01 00:00:00'
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

-- Champion Ban Class
---@class WildriftChampionBan: MatchSummaryRowInterface
---@operator call: WildriftChampionBan
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
---@return self
function ChampionBan:banRow(banData, gameNumber, numberOfBans)
	self.table:tag('tr')
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[1], numberOfBans, false, true))
		:tag('td')
			:node(mw.html.create('div')
				:wikitext(CustomMatchSummary._createAbbreviation{
					title = 'Bans in game ' .. gameNumber,
					text = 'Game ' .. gameNumber,
				})
			)
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[2], numberOfBans, true, true))
	return self
end

---@return Html
function ChampionBan:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '420px'})
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

	if match.dateIsExact or (match.date ~= EPOCH_TIME_EXTENDED and match.date ~= EPOCH_TIME) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex)
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
			banData[1].color = extradata.team1side
			banData[2].color = extradata.team2side
			banData.numberOfBans = numberOfBans
			showGameBans[gameIndex] = banData
		end
	end

	-- Add the Champion Bans
	if not Table.isEmpty(showGameBans) then
		local championBan = ChampionBan()

		for gameIndex, banData in ipairs(showGameBans) do
			championBan:banRow(banData, gameIndex, banData.numberOfBans)
		end

		body:addRow(championBan)
	end

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow?
function CustomMatchSummary._createGame(game, gameIndex)
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

	row	:addClass('brkts-popup-body-game')
		:css('font-size', '85%')
		:css('overflow', 'hidden')

	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[1], NUM_CHAMPIONS_PICK, false))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(CustomMatchSummary._createAbbreviation{
			title = Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length',
			text = Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
		})
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[2], NUM_CHAMPIONS_PICK, true))

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

---@param args table
---@return string
function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

---@param opponentChampionsData table
---@param numberOfChampions integer
---@param flip boolean?
---@param isBan boolean?
---@return Html
function CustomMatchSummary._opponentChampionsDisplay(opponentChampionsData, numberOfChampions, flip, isBan)
	local opponentChampionsDisplay = {}
	local color = opponentChampionsData.color or ''
	opponentChampionsData.color = nil

	for index = 1, numberOfChampions do
		local champDisplay = mw.html.create('div')
		:addClass('brkts-popup-side-color-' .. color)
		:css('float', flip and 'right' or 'left')
		:node(ChampionIcon._getImage{
			champ = opponentChampionsData[index],
			class = 'brkts-champion-icon',
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
