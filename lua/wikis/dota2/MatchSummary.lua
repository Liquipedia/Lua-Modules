---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@class Dota2MatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local Dota2MatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class Dota2CustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = Dota2MatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	local options = {width = '400px', teamStyle = 'bracket', maxBans = MAX_NUM_BANS}
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
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
			extradata, 'team' .. opponentIndex .. 'hero', NUM_HEROES_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
end

return CustomMatchSummary
