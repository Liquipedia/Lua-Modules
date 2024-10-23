---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Page = require('Module:Page')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ICONS = {
	check = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'},
	empty = '[[File:NoCheck.png|link=]]'
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

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

function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div'):wikitext(game.scores[opponentIndex])
end

function CustomMatchSummary._createMapRow(game)
	if not game.map then
		return
	end

	local characterData = {
		Array.map((game.opponents[1] or {}).players or {}, Operator.property('striker')),
		Array.map((game.opponents[2] or {}).players or {}, Operator.property('striker')),
	}

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
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = mw.html.create('div'):addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		return container:node(ICONS[iconType])
	end

	return container:node(ICONS.empty)
end

return CustomMatchSummary
