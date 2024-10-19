---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchPage = Lua.import('Module:MatchPage')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Opponent = Lua.import('Module:Opponent')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	if
		Logic.readBool(match.extradata.headtohead) and
		match.opponents[1].type == Opponent.team and
		match.opponents[2].type == Opponent.team
	then
		local team1, team2 = string.gsub(match.opponents[1].name, ' ', '_'), string.gsub(match.opponents[2].name, ' ', '_')
		match.links.headtohead = tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
		'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' .. team1 ..
		'&Head_to_head_query%5Bopponent%5D=' .. team2 .. '&wpRunQuery=Run+query'
	end

	return footer:addLinks(MatchLinks, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	-- Original Match Id must be used to match page links if it exists.
	-- It can be different from the matchId when shortened brackets are used.
	local matchId = match.extradata.originalmatchid or match.matchId

	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local showMatchPage = MatchPage.isEnabledFor(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		showMatchPage and MatchSummaryWidgets.MatchPageLink{matchId = matchId} or nil,
		unpack(Array.map(match.games, CustomMatchSummary._createGame)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		MatchSummary.makeCastersRow(match.extradata.casters)
	)}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local extradata = game.extradata or {}

	local heroesData = {{}, {}}
	for heroIndex = 1, NUM_HEROES_PICK do
		if String.isNotEmpty(extradata['team1hero' .. heroIndex]) then
			heroesData[1][heroIndex] = extradata['team1hero' .. heroIndex]
		end
		if String.isNotEmpty(extradata['team2hero' .. heroIndex]) then
			heroesData[2][heroIndex] = extradata['team2hero' .. heroIndex]
		end
	end

	-- Add Comment
	local comment = {}
	if Logic.isNotEmpty(game.comment) then
		comment = {
			MatchSummary.Break():create(),
			HtmlWidgets.Div{css = {margin = 'auto'}, children = game.comment},
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '80%', padding = '4px'},
		children = {
			MatchSummaryWidgets.Characters{
				flipped = false,
				characters = heroesData[1],
				bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
			},
			CustomMatchSummary._createCheckMark(game.winner == 1),
			HtmlWidgets.Div{
				classes = {'brkts-popup-body-element-vertical-centered'},
				children = {Logic.isNotEmpty(game.length) and game.length or ('Game ' .. gameIndex)},
			},
			CustomMatchSummary._createCheckMark(game.winner == 2),
			MatchSummaryWidgets.Characters{
				flipped = true,
				characters = heroesData[2],
				bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
			},
			unpack(comment)
		}
	}
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
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

---@param args table
---@return string
function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

return CustomMatchSummary
