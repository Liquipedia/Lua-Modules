---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@enum AFPSMatchIcons
local Icons = {
	CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'},
	EMPTY = '[[File:NoCheck.png|link=]]',
}

local LINK_DATA = {
	dbstats = {icon = 'File:Diabotical icon.png', text = 'QuakeLife matchpage'},
	qrindr = {icon = 'File:Quake Champions icon.png', text = 'Qrindr matchpage'},
	pf = {icon = 'File:Plus Forward icon.png', text = 'Plus Forward matchpage'},
	esl = {icon = 'File:ESL icon.png', text = 'Match page and stats on ESL'},
	interview = {icon = 'File:Int_Icon.png', text = 'Interview'},
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

	return footer:addLinks(LINK_DATA, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
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
	if Table.isNotEmpty(match.extradata.mvp) then
		body.root:node(MatchSummaryWidgets.Mvp{
			players = match.extradata.mvp.players,
			points = match.extradata.mvp.points,
		})
	end

	-- Add casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

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
		:node(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))
		:css('width', '20%')

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(DisplayHelper.MapScore(game.scores[2], 2, game.resultType, game.walkover, game.winner))
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
---@param iconType string?
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = mw.html.create('div'):addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		return container:node(iconType)
	end
	return container:node(Icons.EMPTY)
end

return CustomMatchSummary
