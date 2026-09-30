---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 5
local NUM_CHAMPIONS_PICK = 5

---@class MobileLegendsMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local MobileLegendsMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class MobileLegendsCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = MobileLegendsMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	local options = {width = '420px', teamStyle = 'hybrid', maxBans = MAX_NUM_BANS}
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	local function hasCharacterData()
		local extradata = game.extradata or {}
		return Array.any(Array.range(1, NUM_CHAMPIONS_PICK), function (index)
			return Logic.isNotEmpty(extradata['team1champion' .. index])
				or Logic.isNotEmpty(extradata['team2champion' .. index])
		end)
	end
	return Logic.isNotEmpty(game.length) or Logic.isNotEmpty(game.winner) or hasCharacterData()
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
			extradata, 'team' .. opponentIndex .. 'champion', NUM_CHAMPIONS_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
end

return CustomMatchSummary
