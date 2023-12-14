---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local MAP_VETO_START = '<b>Start Map Veto</b>'
local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'
local NONE = '-'
local TBD = Abbreviation.make('TBD', 'To Be Determined') --[[@as string]]

---@enum AFPSMatchIcons
local Icon = {
	CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>',
	EMPTY = '[[File:NoCheck.png|link=]]',
}

local LINK_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport.png', text = 'Live Report Thread'},
	quakehistory = {icon = 'File:Quake history icon', text = 'Quake History matchpage'},
	dbstats = {icon = 'File:Diabotical icon.png', text = 'QuakeLife matchpage'},
	qrindr = {icon = 'File:Quake Champions icon.png', text = 'Qrindr matchpage'},
	pf = {icon = 'File:Plus Forward icon.png', text = 'Plus Forward matchpage'},
	esl = {icon = 'File:ESL icon.png', text = 'Match page and stats on ESL'},
	interview = {icon = 'File:Int_Icon.png', text = 'Interview'},
	review = {icon = 'File::Writers_Icon.png', text = 'Review'},
	recap = {icon = 'File::Writers_Icon.png', text = 'Recap'},
}

local VETO_TYPE_TO_TEXT = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',

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

	if match.dateIsExact or match.timestamp ~= DateExt.epochZero then
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

	-- Add casters
	if String.isNotEmpty(match.extradata.casters) then
		local casters = Json.parseIfString(match.extradata.casters)
		local casterRow = MatchSummary.Casters()
		for _, caster in pairs(casters) do
			casterRow:addCaster(caster)
		end

		body:addRow(casterRow)
	end

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
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, Icon.CHECK))
		:node(CustomMatchSummary._gameScore(game, 1))
		:css('width', '20%')

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, Icon.CHECK))
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
---@param iconType AFPSMatchIcons?
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = mw.html.create('div'):addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		return container:node(iconType)
	end
	return container:node(Icon.EMPTY)
end

return CustomMatchSummary
