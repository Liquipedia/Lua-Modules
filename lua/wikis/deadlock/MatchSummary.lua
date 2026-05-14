---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
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

---@class DeadlockCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class DeadlockMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): DeadlockMatchSummaryGameRow
local DeadlockMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if game.status == STATUS_NOT_PLAYED then
					return
				end
				return DeadlockMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@private
---@param opponentIndex integer
---@return string[]
function DeadlockMatchSummaryGameRow:_getHeroesForOpponent(opponentIndex)
	local opponent = self.props.game.opponents[opponentIndex]
	return Array.map(opponent.players or {}, Operator.property('character'))
end

---@param opponentIndex integer
---@return Widget
function DeadlockMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	local props = self.props
	local game = props.game
	local extradata = game.extradata or {}

	return WidgetUtil.collect(
		ICONS[extradata['team' .. opponentIndex .. 'side']],
		MatchSummaryWidgets.Characters{
			characters = self:_getHeroesForOpponent(opponentIndex),
			flipped = opponentIndex == 2,
			hideOnMobile = true,
		}
	)
end

---@return Renderable?
function DeadlockMatchSummaryGameRow:createGameOverview()
	return self:lengthDisplay()
end

return CustomMatchSummary
