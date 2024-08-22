---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

---@enum TFMatchIcons
local Icons = {
	CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'},
	EMPTY = '[[File:NoCheck.png|link=]]',
}

local LINK_DATA = {
	logstf = {icon = 'File:Logstf_icon.png', text = 'logs.tf Match Page '},
	logstfgold = {icon = 'File:Logstf_gold_icon.png', text = 'logs.tf Match Page (Golden Cap) '},
	esl = {
		icon = 'File:ESL 2019 icon lightmode.png',
		iconDark = 'File:ESL 2019 icon darkmode.png',
		text = 'ESL matchpage'
	},
	esea = {icon = 'File:ESEA icon allmode.png', text = 'ESEA Match Page'},
	etf2l = {icon = 'File:ETF2L.png', text = 'ETF2L Match Page'},
	rgl = {icon = 'File:RGL_Logo.png', text = 'RGL Match Page'},
	ozf = {icon = 'File:ozfortress-icon.png‎', text = 'ozfortress Match Page'},
	tftv = {icon = 'File:Teamfortress.tv.png', text = 'TFTV Match Page'},
}

local CustomMatchSummary = {}

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
		:addLinks(LINK_DATA, match.links)

	---@param link string?
	---@param linkType string
	---@param gameIndex integer
	local addLink = function(link, linkType, gameIndex)
		if Logic.isEmpty(link) then return end
		local linkData = LINK_DATA[linkType]
		footer:addLink(link, linkData.icon, linkData.iconDark, linkData.text .. 'for game ' .. gameIndex)
	end

	return footer
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or DateExt.isDefaultTimestamp(match.timestamp) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default timestamp, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	Array.forEach(match.games, function(game)
		if not game.map then return end
		body:addRow(CustomMatchSummary._createMapRow(game))
	end)

	return body
end
---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div'):wikitext(game.scores[opponentIndex])
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
		:wikitext(Page.makeInternalLink(game.map))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, Icons.CHECK))
		:node(CustomMatchSummary._gameScore(game, 1))
		:css('width', '20%')

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, Icons.CHECK))
		:css('width', '20%')

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

---@param showIcon boolean?
---@param icon strings?
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, icon)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '27px')
		:node(showIcon and icon or Icons.EMPTY)
end

return CustomMatchSummary
