---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local String = require('Module:StringUtils')
local MapModes = require('Module:MapModes')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local htmlCreate = mw.html.create

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local ICONS = {
	check = GREEN_CHECK,
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
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
	if Table.isNotEmpty(match.extradata.mvp) then
		body.root:node(MatchSummaryWidgets.Mvp{
			players = match.extradata.mvp.players,
			points = match.extradata.mvp.points,
		})
	end

	-- casters
	body.root:node(MatchSummaryWidgets.Casters{casters = match.extradata.casters})

	return body
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] --[[@as number|string?]]
	if score and game.mode == 'Push' then
		score = score .. 'm'
	end
	local scoreDisplay = DisplayHelper.MapScore(score, opponentIndex, game.resultType, game.walkover, game.winner)
	return htmlCreate('div'):wikitext(scoreDisplay)
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = htmlCreate('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = htmlCreate('div')
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
		local comment = htmlCreate('div')
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
	if String.isNotEmpty(game.mode) then
		mapDisplay = MapModes.get{mode = game.mode} .. mapDisplay
	end
	return mapDisplay
end

---@param showIcon boolean
---@param iconType string
---@return Html
function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = htmlCreate('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(ICONS[iconType])
	else
		container:node(NO_CHECK)
	end

	return container
end

return CustomMatchSummary
