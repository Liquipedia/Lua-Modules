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
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 5
local NUM_CHAMPIONS_PICK = 5

---@class HoKCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

local HoKMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent{
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
	createGameOpponentView = CustomMatchSummary.createGameOpponentView
}

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '420px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	---@param game MatchGroupUtilGame
	---@return boolean
	local function hasCharacterData(game)
		local extradata = game.extradata or {}
		return Array.any(Array.range(1, NUM_CHAMPIONS_PICK), function (index)
			return Logic.isNotEmpty(extradata['team1champion' .. index])
				or Logic.isNotEmpty(extradata['team2champion' .. index])
		end)
	end

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.length) and Logic.isEmpty(game.winner) and not hasCharacterData(game) then
					return
				end
				return HoKMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function CustomMatchSummary.createGameOpponentView(props, opponentIndex)
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
