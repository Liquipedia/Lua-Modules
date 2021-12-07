---
-- @Liquipedia
-- wiki=splitgate
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local htmlCreate = mw.html.create

local _GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local _ICONS = {
	check = _GREEN_CHECK,
}
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'File:Preview Icon.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport.png', text = 'LiveReport.png'},
}

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()

	matchSummary:header(CustomMatchSummary._createHeader(match))
		:body(CustomMatchSummary._createBody(match))

	-- comment
	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	-- footer
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	match.links.lrthread = match.lrthread
	match.links.vod = match.vod
	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		-- Match Vod + other links
		local buildLink = function (linkType, link)
			local linkData = _LINK_DATA[linkType]
			if not linkData then
				mw.log('linkType "' .. linkType .. '" is not supported by Module:MatchSummary')
			else
				return '[[' .. linkData.icon .. '|link=' .. link .. '|15px|' .. linkData.text .. ']]'
			end
		end

		for linkType, link in pairs(match.links) do
			footer:addElement(buildLink(linkType,link))
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end


function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(CustomMatchSummary._createOpponent(match.opponents[1], 'left'))
	      :leftScore(CustomMatchSummary._createScore(match.opponents[1]))
	      :rightScore(CustomMatchSummary._createScore(match.opponents[2]))
	      :rightOpponent(CustomMatchSummary._createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createScore(opponent)
	return OpponentDisplay.BlockScore{
		isWinner = opponent.placement == 1,
		scoreText = OpponentDisplay.InlineScore(opponent),
	}
end

function CustomMatchSummary._createOpponent(opponent, side)
	return OpponentDisplay.BlockOpponent{
		flip = side == 'left',
		opponent = opponent,
		overflow = 'wrap',
		teamStyle = 'short',
	}
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= _EPOCH_TIME_EXTENDED and match.date ~= _EPOCH_TIME) then
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

	return body
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] or ''
	return htmlCreate('div'):wikitext(score)
end

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
		:wikitext('[[' .. game.map .. ']]')
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

function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = htmlCreate('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(_ICONS[iconType])
	else
		container:node(_NO_CHECK)
	end

	return container
end

return CustomMatchSummary
