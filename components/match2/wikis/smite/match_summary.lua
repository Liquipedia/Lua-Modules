---
-- @Liquipedia
-- wiki=smite
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
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local Opponent = Lua.import('Module:Opponent')

local MAX_NUM_BANS = 5
local NUM_GODS_PICK_TEAM = 5
local NUM_GODS_PICK_SOLO = 1
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'

-- God Ban Class
---@class SmiteGodBan: MatchSummaryRowInterface
---@operator call: SmiteGodBan
---@field root Html
---@field table Html
---@field date string
local GodBan = Class.new(
	function(self, date)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self.date = date
		self:createHeader()
	end
)

---@return self
function GodBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width', '40%'):wikitext(''):done()
		:tag('th'):css('width', '20%'):wikitext('Bans'):done()
		:tag('th'):css('width', '40%'):wikitext(''):done()
	return self
end

---@param banData {numberOfBans: integer, [1]: table, [2]: table}
---@param gameNumber integer
---@param numberOfBans integer
---@return self
function GodBan:banRow(banData, gameNumber, numberOfBans)
	self.table:tag('tr')
		:tag('td'):css('float', 'left')
			:node(CustomMatchSummary._opponentGodsDisplay(banData[1], numberOfBans, true, self.date))
		:tag('td'):css('font-size', '80%'):node(mw.html.create('div')
			:wikitext(Abbreviation.make(
				'Game ' .. gameNumber,
				'Bans in game ' .. gameNumber
			))
		)
		:tag('td'):css('float', 'right')
			:node(CustomMatchSummary._opponentGodsDisplay(banData[2], numberOfBans, true, self.date))
	return self
end


---@return Html
function GodBan:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
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

	-- casters
	if String.isNotEmpty(match.extradata.casters) then
		local casters = Json.parseIfString(match.extradata.casters)
		local casterRow = MatchSummary.Casters()
		Array.forEach(casters, FnUtil.curry(casterRow.addCaster, casterRow))

		body:addRow(casterRow)
	end

	-- Pre-Process God Ban Data
	local godBans = {}
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
			godBans[gameIndex] = banData
		end
	end

	-- Add the God Bans
	if not Table.isEmpty(godBans) then
		local godBan = GodBan(match.date)

		for gameIndex in ipairs(match.games) do
			local banData = godBans[gameIndex]
			if banData then
				godBan:banRow(banData, gameIndex, banData.numberOfBans)
			end
		end

		body:addRow(godBan)
	end

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local numberOfGods = NUM_GODS_PICK_TEAM
	if game.mode == Opponent.solo then
		numberOfGods = NUM_GODS_PICK_SOLO
	end

	local godsData = {{}, {}}
	for godIndex = 1, numberOfGods do
		if String.isNotEmpty(extradata['team1god' .. godIndex]) then
			godsData[1][godIndex] = extradata['team1god' .. godIndex]
		end
		if String.isNotEmpty(extradata['team2god' .. godIndex]) then
			godsData[2][godIndex] = extradata['team2god' .. godIndex]
		end
		godsData[1].side = extradata.team1side
		godsData[2].side = extradata.team2side
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentGodsDisplay(godsData[1], numberOfGods, false, date))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(Abbreviation.make(
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length'
			))
		)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentGodsDisplay(godsData[2], numberOfGods, true, date))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment:wikitext(game.comment):css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
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

---@param opponentgodsData table
---@param numberOfGods integer
---@param flip boolean?
---@param date string
---@return Html
function CustomMatchSummary._opponentGodsDisplay(opponentgodsData, numberOfGods, flip, date)
	local opponentGodsDisplay = {}
	local color = opponentgodsData.side or ''

	for index = 1, numberOfGods do
		local godDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. color)
			:node(CharacterIcon.Icon{
				character = opponentgodsData[index] or NO_CHARACTER,
				date = date
			})
		if numberOfGods == NUM_GODS_PICK_SOLO then
			if flip then
				godDisplay:css('margin-right', '70px')
			else
				godDisplay:css('margin-left', '70px')
			end
		end
		table.insert(opponentGodsDisplay, godDisplay)
	end

	if flip then
		opponentGodsDisplay = Array.reverse(opponentGodsDisplay)
	end

	local display = mw.html.create('div')
		:addClass('brkts-popup-body-element-thumbs')
		:addClass('brkts-popup-body-element-thumbs-' .. (flip and 'right' or 'left'))
		:addClass('brkts-champion-icon')

	for _, item in ipairs(opponentGodsDisplay) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary
