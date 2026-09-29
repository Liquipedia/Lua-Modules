---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@class Standoff2MatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local Standoff2MatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class Standoff2MatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = LabMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return Renderable[]
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	return {
		MatchSummaryWidgets.GameRow.scoreDisplay(props.game, opponentIndex)
	}
end

return CustomMatchSummary
