---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local CardIcon = require('Module:CardIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local NUM_CARDS_PER_PLAYER = 8
local CARD_COLOR_1 = 'blue'
local CARD_COLOR_2 = 'red'
local DEFAULT_CARD = 'transparent'
local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
-- Normal links, from input/lpdb
local LINK_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'Live Report Thread'},
	interview = {icon = 'File:Interview32.png', text = 'Interview'},
	recap = {icon = 'File:Reviews32.png', text = 'Recap'},
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
}
LINK_DATA.review = LINK_DATA.recap
LINK_DATA.preview2 = LINK_DATA.preview
LINK_DATA.interview2 = LINK_DATA.interview

local EPOCH_TIME = '1970-01-01 00:00:00'
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init('520px')
	matchSummary.root:css('flex-wrap', 'unset')

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if not Logic.isEmpty(game.vod) then
			vods[index] = game.vod
		end
	end
	match.links.vod = match.vod

	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Match Vod + other links
		local buildLink = function (link, icon, text)
			return '[['..icon..'|link='..link..'|15px|'..text..']]'
		end

		for linkType, link in pairs(match.links) do
			if not LINK_DATA[linkType] then
				mw.log('Unknown link: ' .. linkType)
			else
				footer:addElement(buildLink(link, LINK_DATA[linkType].icon, LINK_DATA[linkType].text))
			end
		end

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left', 'bracket'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right', 'bracket'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= EPOCH_TIME_EXTENDED and match.date ~= EPOCH_TIME) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	if match.extradata.hasteamopponent then
		return CustomMatchSummary._createTeamMatchBody(body, match)
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		body:addRow(CustomMatchSummary._createGame(game, gameIndex, match.date))
	end

	local extradata = match.extradata
	if Table.isNotEmpty(extradata.t1bans) or Table.isNotEmpty(extradata.t2bans) then
		body:addRow(CustomMatchSummary._banRow(extradata.t1bans, extradata.t2bans, match.date))
	end

	return body
end

function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()

	-- Add game header
	if not Logic.isEmpty(game.header) then
		row:addElement(mw.html.create('div')
			:wikitext(game.header)
			:css('margin', 'auto')
			:css('font-weight', 'bold')
		)
		row:addElement(MatchSummary.Break():create())
	end

	local cardData = {{}, {}}
	for participantKey, participantData in Table.iter.spairs(game.participants or {}) do
		local opponentIndex = tonumber(mw.text.split(participantKey, '_')[1])
		local cards = participantData.cards or {}
		for _ = #cards + 1, NUM_CARDS_PER_PLAYER do
			table.insert(cards, DEFAULT_CARD)
		end
		table.insert(cardData[opponentIndex], cards)
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentCardsDisplay(cardData[1], true, date))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext('Game ' .. gameIndex)
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentCardsDisplay(cardData[2], false, date))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		row:addElement(mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		)
	end

	return row
end

function CustomMatchSummary._banRow(t1bans, t2bans, date)
	local maxAmountOfBans = math.max(#t1bans, #t2bans)
	for banIndex = 1, maxAmountOfBans do
		t1bans[banIndex] = t1bans[banIndex] or DEFAULT_CARD
		t2bans[banIndex] = t2bans[banIndex] or DEFAULT_CARD
	end

	local banRow = MatchSummary.Row()

	banRow:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	banRow:addElement(mw.html.create('div')
		:wikitext('Bans')
		:css('margin', 'auto')
		:css('font-weight', 'bold')
	)
	banRow:addElement(MatchSummary.Break():create())

	banRow:addElement(CustomMatchSummary._opponentCardsDisplay({t1bans}, true, date))
	banRow:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext('Bans')
	)
	banRow:addElement(CustomMatchSummary._opponentCardsDisplay({t2bans}, false, date))

	return banRow
end

-- todo
function CustomMatchSummary._createTeamMatchBody(body, match)
	local row = MatchSummary.Row()
	row:addElement(mw.html.create('div')
		:addClass('error')
		:wikitext('MatchSummary is currently not ready for matches including team opponents')
		:css('margin', 'auto')
	)

	body:addRow(row)

	return body
end

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

function CustomMatchSummary._opponentCardsDisplay(cardDataSets, flip, date)
	local color = flip and CARD_COLOR_2 or CARD_COLOR_1
	local wrapper = mw.html.create('div')

	for _, cardData in ipairs(cardDataSets) do
		local cardDisplays = {}
		for _, card in ipairs(cardData) do
			table.insert(cardDisplays, mw.html.create('div')
				:addClass('brkts-popup-side-color-' .. color)
				:addClass('brkts-champion-icon')
				:css('float', flip and 'right' or 'left')
				:node(CardIcon._getImage{card, date = date})
			)
		end

		if flip then
			cardDisplays = Array.reverse(cardDisplays)
		end

		local display = mw.html.create('div')
			:addClass('brkts-popup-body-element-thumbs')

		for _, card in ipairs(cardDisplays) do
			display:node(card)
		end

		wrapper:node(display)
	end

	return wrapper
end

return CustomMatchSummary
