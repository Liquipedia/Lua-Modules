---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapTypeIcon = require('Module:MapType')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local LEFT_SIDE = 1
local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|First pick]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|First pick]]'

local GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local ICONS = {
	check = GREEN_CHECK,
}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'
local LINK_DATA = {}

local CustomMatchSummary = {}


-- Brawler Pick/Ban Class
---@class BrawlstarsMatchSummaryBrawler: MatchSummaryRowInterface
---@operator call: BrawlstarsMatchSummaryBrawler
---@field root Html
---@field table Html
---@field isBan boolean?
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

---@return self
function Brawler:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','35%'):wikitext(''):done()
		:tag('th'):css('width','5%'):wikitext(''):done()
		:tag('th'):css('width','20%'):wikitext(self.isBan and 'Bans' or 'Picks'):done()
		:tag('th'):css('width','5%'):wikitext(''):done()
		:tag('th'):css('width','35%'):wikitext(''):done()
	return self
end

---@param brawlerData {[1]: table<integer, string>, [2]: table<integer, string>, numberOfPicks: integer}
---@param gameNumber integer
---@param numberBrawlers integer
---@param date string
---@param firstPick integer?
---@return self
function Brawler:row(brawlerData, gameNumber, numberBrawlers, date, firstPick)
	if numberBrawlers > 0 then
		self.table:tag('tr')
			:tag('td')
				:node(self:_opponentBrawlerDisplay(brawlerData[1], numberBrawlers, false, date))
			:tag('td'):wikitext(Brawler._firstPick(firstPick, 1))
			:tag('td')
				:node(mw.html.create('div')
					:wikitext(Abbreviation.make(
							'Set ' .. gameNumber,
							(self.isBan and 'Bans' or 'Picks') .. ' in set ' .. gameNumber
						)
					)
				)
			:tag('td'):wikitext(Brawler._firstPick(firstPick, 2))
			:tag('td')
				:node(self:_opponentBrawlerDisplay(brawlerData[2], numberBrawlers, true, date))
	end

	return self
end

---@param firstPick integer?
---@param side integer
---@return string?
function Brawler._firstPick(firstPick, side)
	if firstPick ~= side then
		return nil
	end

	return side == LEFT_SIDE and ARROW_LEFT or ARROW_RIGHT
end

---@param brawlerData table<integer, string>
---@param numberOfBrawlers integer
---@param flip boolean
---@param date string
---@return Html
function Brawler:_opponentBrawlerDisplay(brawlerData, numberOfBrawlers, flip, date)
	local opponentBrawlerDisplay = {}

	for index = 1, numberOfBrawlers do
		local brawlerDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. (flip and 'red' or 'blue'))
			:css('float', flip and 'right' or 'left')
			:node(CharacterIcon.Icon{
				character = brawlerData[index] or NO_CHARACTER,
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

---@return Html
function Brawler:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)


	return footer:addLinks(LINK_DATA, match.links)
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
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMapRow(game))
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

	-- Pre-Process Brawler picks
	local showGamePicks = {}
	for gameIndex, game in ipairs(match.games) do
		local pickData = {{}, {}}
		local participants = game.participants
		local index = 1
		while true do
			if Table.isEmpty(participants['1_' .. index]) and Table.isEmpty(participants['2_' .. index]) then
				break
			end
			if Table.isNotEmpty(participants['1_' .. index]) then
				pickData[1][index] = participants['1_' .. index].brawler
			end
			if Table.isNotEmpty(participants['2_' .. index]) then
				pickData[2][index] = participants['2_' .. index].brawler
			end
			index = index + 1
		end

		if index > 1 then
			pickData.numberOfPicks = index - 1
			showGamePicks[gameIndex] = pickData
		end
	end

	-- Add the Brawler picks
	if not Table.isEmpty(showGamePicks) then
		local brawler = Brawler({isBan = false})

		for gameIndex, pickData in ipairs(showGamePicks) do
			brawler:row(pickData, gameIndex, pickData.numberOfPicks, match.date, match.games[gameIndex].extradata.firstpick)
		end

		body:addRow(brawler)
	end

	-- Pre-Process Brawler bans
	local showGameBans = {}
	for gameIndex, game in ipairs(match.games) do
		local extradata = game.extradata or {}
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

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex]
	local scoreDisplay = DisplayHelper.MapScore(score, opponentIndex, game.resultType, game.walkover, game.winner)
	return mw.html.create('div'):wikitext(scoreDisplay)
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = mw.html.create('div')
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
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'
	if String.isNotEmpty(game.extradata.maptype) then
		return MapTypeIcon.display(game.extradata.maptype) .. mapDisplay
	end
	return mapDisplay
end

---@param showIcon boolean
---@param iconType string
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(ICONS[iconType])
	else
		container:node(NO_CHECK)
	end

	return container
end

return CustomMatchSummary
