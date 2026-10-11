---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 1

---@class OverwatchMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {}

local OverwatchMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class OverwatchCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = OverwatchMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {maxBans = MAX_NUM_BANS})
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return Logic.isNotEmpty(game.map)
end

---@param props MatchSummaryGameRowProps
---@return string
function GameRowComponentProps.createGameOverview(props)
	return DisplayHelper.MapAndMode(props.game)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return Renderable
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local opponentCopy = Table.deepCopy(game.opponents[opponentIndex])
	if opponentCopy.score and game.mode == 'Push' then
		---@diagnostic disable-next-line: assign-type-mismatch
		opponentCopy.score = opponentCopy.score .. 'm'
	end

	return DisplayHelper.MapScore(opponentCopy, game.status)
end

return CustomMatchSummary
