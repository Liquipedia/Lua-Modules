---
-- @Liquipedia
-- wiki=smite
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 5
local NUM_GODS_PICK = 5

local LINK_DATA = {
	smiteesports = {
		icon = 'File:SMITE default lightmode.png',
		iconDark = 'File:SMITE default darkmode.png',
		text = 'Smite Esports Match Page'
	},
	stats = {icon = 'File:Match_Info_Stats.png', text = 'Match Statistics'},
}

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
	return footer:addLinks(LINK_DATA, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)
	local casterRow = MatchSummary.makeCastersRow(match.extradata.casters)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		unpack(Array.map(match.games, FnUtil.curry(CustomMatchSummary._createGame, match.date))),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		casterRow and casterRow:create() or nil
	)}
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(date, game, gameIndex)
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1god', NUM_GODS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2god', NUM_GODS_PICK),
	}

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
				date = date,
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
				date = date,
			},
			unpack(comment)
		}
	}
end

return CustomMatchSummary
