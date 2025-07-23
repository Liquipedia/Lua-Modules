---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 6
local ICONS = {
	amber = Icon.makeIcon{iconName = 'amberhand', color = 'deadlock-amberhand-text', size = 'initial'},
	sapphire = Icon.makeIcon{iconName = 'sapphireflame', color = 'deadlock-sapphireflame-text', size = 'initial'},
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '440px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		Array.map(match.games, CustomMatchSummary._createGame),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param players table[]
---@return table
function CustomMatchSummary._getHeroesForOpponent(players)
	return Array.map(players or {}, Operator.property('character'))
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '80%', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._createIcon(ICONS[extradata.team1side]),
			MatchSummaryWidgets.Characters{
				characters = CustomMatchSummary._getHeroesForOpponent(game.opponents[1].players),
				flipped = false,
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = Logic.nilIfEmpty(game.length) or ('Game ' .. gameIndex)},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				characters = CustomMatchSummary._getHeroesForOpponent(game.opponents[2].players),
				flipped = true,
			},
			CustomMatchSummary._createIcon(ICONS[extradata.team2side]),
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param icon string
---@return Html
function CustomMatchSummary._createIcon(icon)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:wikitext(icon)
end

return CustomMatchSummary
