---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@class TrackmaniaMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local TrackmaniaMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class TrackmaniaCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = TrackmaniaMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return Logic.isNotEmpty(game.map)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return Renderable[]
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return {
		MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
		extradata.overtime and IconFa{
			iconName = 'time',
			hover = 'Overtime',
		} or nil,
	}
end

return CustomMatchSummary
