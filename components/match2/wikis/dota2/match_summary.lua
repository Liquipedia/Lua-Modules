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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchPage = Lua.import('Module:MatchPage')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5

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
	local casterRow = MatchSummary.makeCastersRow(match.extradata.casters)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		showMatchPage and MatchSummaryWidgets.MatchPageLink{matchId = matchId} or nil,
		unpack(Array.map(match.games, CustomMatchSummary._createGame)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		casterRow and casterRow:create() or nil
	)}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1hero', NUM_HEROES_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2hero', NUM_HEROES_PICK),
	}

	-- Map Comment
	local comment = Logic.isNotEmpty(game.comment) and {
		MatchSummaryWidgets.Break{},
		HtmlWidgets.Div{css = {margin = 'auto'}, children = game.comment},
	} or {}

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '80%', padding = '4px'},
		children = {
			MatchSummaryWidgets.Characters{
				flipped = false,
				characters = characterData[1],
				bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			HtmlWidgets.Div{
				classes = {'brkts-popup-body-element-vertical-centered'},
				children = {Logic.isNotEmpty(game.length) and game.length or ('Game ' .. gameIndex)},
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				flipped = true,
				characters = characterData[2],
				bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
			},
			unpack(comment)
		}
	}
end

return CustomMatchSummary
