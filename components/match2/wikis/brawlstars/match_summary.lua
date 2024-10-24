---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapTypeIcon = require('Module:MapType')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local ICONS = {
	check = GREEN_CHECK,
}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local characterBansData = Array.map(match.games, function (game)
		local extradata = game.extradata or {}
		local bans = extradata.bans or {}
		return {bans.team1 or {}, bans.team2 or {}}
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMapRow),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)}
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
---@return Html?
function CustomMatchSummary._createMapRow(game)
	if not game.map then
		return
	end

	local characterData = {
		Array.map((game.opponents[1] or {}).players or {}, Operator.property('brawler')),
		Array.map((game.opponents[2] or {}).players or {}, Operator.property('brawler')),
	}

	local row = MatchSummary.Row()

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(MatchSummaryWidgets.Characters{
			flipped = false,
			characters = characterData[1],
			bg = 'brkts-popup-side-color-blue', -- Team 1 is always blue
		})
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, 'check'))
		:node(MatchSummaryWidgets.Characters{
			flipped = true,
			characters = characterData[2],
			bg = 'brkts-popup-side-color-red', -- Team 2 is always red
		})

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row:create()
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
