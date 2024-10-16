---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 6
local ICONS = {
	winner = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'},
	loss = Icon.makeIcon{iconName = 'loss', color = 'cinnabar-text', size = 'initial'},
	amber = Icon.makeIcon{iconName = 'amberhand', color = 'deadlock-amberhand-text', size = 'initial'},
	sapphire = Icon.makeIcon{iconName = 'sapphireflame', color = 'deadlock-sapphireflame-text', size = 'initial'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

local CustomMatchSummary = {}

-- Hero Ban Class
---@class DeadlockHeroBan: MatchSummaryRowInterface
---@operator call: DeadlockHeroBan
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
		:tag('th'):css('width', '40%'):wikitext(''):done()
		:tag('th'):css('width', '20%'):wikitext('Bans'):done()
		:tag('th'):css('width', '40%'):wikitext(''):done()
	return self
end

---@param banData {numberOfBans: integer, [1]: table, [2]: table}
---@param gameNumber integer
---@return self
function HeroBan:banRow(banData, gameNumber)
	self.table:tag('tr')
		:tag('td'):css('float', 'left')
			:node(CustomMatchSummary._createCharacterDisplay(banData[1], false))
		:tag('td'):css('font-size', '80%'):node(mw.html.create('div')
			:wikitext(Abbreviation.make(
				'Game ' .. gameNumber,
				'Bans in game ' .. gameNumber
			))
		)
		:tag('td'):css('float', 'right')
			:node(CustomMatchSummary._createCharacterDisplay(banData[2], true))
	return self
end


---@return Html
function HeroBan:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '440px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
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

	-- Pre-Process Hero Ban Data
	local heroBanData = {}
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
			heroBanData[gameIndex] = banData
		end
	end

	-- Add the Hero Bans
	if not Table.isEmpty(heroBanData) then
		local heroBan = HeroBan()

		for gameIndex, banData in ipairs(heroBanData) do
			heroBan:banRow(banData, gameIndex)
		end

		body:addRow(heroBan)
	end

	return body
end

---@param participants table
---@param opponentIndex integer
---@return table
function CustomMatchSummary._getHeroesForOpponent(participants, opponentIndex)
	local characters = {}
	for _, participant in Table.iter.pairsByPrefix(participants, opponentIndex .. '_') do
		table.insert(characters, participant.character)
	end
	return characters
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')

	local function makeCharacterDisplay(opponentIndex)
		return MatchSummaryWidgets.Characters{
			characters = CustomMatchSummary._getHeroesForOpponent(game.participants, opponentIndex),
			flipped = opponentIndex == 2,
		}
	end

	row:addElement(CustomMatchSummary._createIcon(ICONS[extradata.team1side]))
	row:addElement(makeCharacterDisplay(1))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(Abbreviation.make(
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length'
		))
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
	row:addElement(makeCharacterDisplay(2))
	row:addElement(CustomMatchSummary._createIcon(ICONS[extradata.team2side]))

	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		row:addElement(mw.html.create('div'):css('margin', 'auto'):wikitext(game.comment))
	end

	return row
end

---@param winner integer|string
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return CustomMatchSummary._createIcon(
			winner == opponentIndex and ICONS.winner
			or winner == 0 and ICONS.draw
			or Logic.isNotEmpty(winner) and ICONS.loss
			or ICONS.empty
		)
end

---@param icon string
---@return Html
function CustomMatchSummary._createIcon(icon)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:wikitext(icon)
end

return CustomMatchSummary
