---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 5
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@class LoLMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local LoLMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class LoLCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = LoLMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', maxBans = MAX_NUM_BANS})
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return game.status ~= STATUS_NOT_PLAYED
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Characters{
		flipped = opponentIndex == 2,
		characters = MatchSummary.buildCharacterList(
			extradata, 'team' .. opponentIndex .. 'champion', NUM_HEROES_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
end

return CustomMatchSummary
