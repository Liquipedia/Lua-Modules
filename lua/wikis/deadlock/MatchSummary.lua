---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Operator = Lua.import('Module:Operator')

local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 6
local ICONS = {
	amber = IconFa{iconName = 'amberhand', color = 'deadlock-amberhand-text', size = 'initial'},
	sapphire = IconFa{iconName = 'sapphireflame', color = 'deadlock-sapphireflame-text', size = 'initial'},
}
local STATUS_NOT_PLAYED = 'notplayed'

---@class DeadlockMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local DeadlockMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class DeadlockCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = DeadlockMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	local options = {width = '480px', teamStyle = 'bracket', maxBans = MAX_NUM_BANS}
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return game.status ~= STATUS_NOT_PLAYED
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return string[]
function GameRowComponentProps._getHeroesForOpponent(game, opponentIndex)
	local opponent = game.opponents[opponentIndex]
	return Array.map(opponent.players or {}, Operator.property('character'))
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode[]
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return WidgetUtil.collect(
		ICONS[extradata['team' .. opponentIndex .. 'side']],
		MatchSummaryWidgets.Characters{
			characters = GameRowComponentProps._getHeroesForOpponent(game, opponentIndex),
			flipped = opponentIndex == 2,
			hideOnMobile = true,
		}
	)
end

return CustomMatchSummary
